@preconcurrency import AVFoundation

/// Letter sounds that can be *held*: while a finger rests on a tile its sound
/// keeps going (/mmmmm/), and moving to the next tile crossfades into the next
/// sound with no gap. That is what makes Stretchy Blend work.
///
/// Sources, best first:
/// 1. `Media/phonemes/<g>.m4a` recordings (optionally `<g>-long.m4a` to loop)
/// 2. The Star Voice's TTS rendered offline from IPA, with a steady middle
///    slice cut out and crossfade-looped for continuous sounds.
///
/// Stop sounds (t, p, b, d, k, g...) can't be held; they play once as a pop.
@MainActor
final class PhonemeEngine {
    private struct Sound {
        let onset: AVAudioPCMBuffer
        let loop: AVAudioPCMBuffer?
    }

    private let engine = AVAudioEngine()
    private let nodes = [AVAudioPlayerNode(), AVAudioPlayerNode()]
    private var active = 0
    private var cache: [String: Sound] = [:]
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let renderer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?
    private var fadeTasks: [Int: Task<Void, Never>] = [:]
    private(set) var current: String?

    init(voice: AVSpeechSynthesisVoice?) {
        self.voice = voice
        for node in nodes {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
        try? engine.start()
    }

    /// Render (or load) the sounds for these graphemes ahead of time.
    func prepare(_ graphemes: [String]) async {
        for g in Set(graphemes.map { $0.lowercased() }) where !g.isEmpty && cache[g] == nil {
            if let sound = await build(g) { cache[g] = sound }
        }
    }

    var continuousGraphemes: Set<String> {
        Set(LetterSounds.table.filter { $0.value.continuous }.keys)
    }

    /// Start (or switch to) holding a grapheme's sound.
    func hold(_ grapheme: String) {
        let g = grapheme.lowercased()
        if g.isEmpty { release(); return } // silent letter (magic e)
        guard g != current, let sound = cache[g] else { return }
        if !engine.isRunning { try? engine.start() }
        fadeOut(active)
        active = (active + 1) % nodes.count
        let node = nodes[active]
        fadeTasks[active]?.cancel()
        node.stop()
        node.volume = 1
        node.scheduleBuffer(sound.onset, at: nil, options: [])
        if let loop = sound.loop {
            node.scheduleBuffer(loop, at: nil, options: .loops)
        }
        node.play()
        current = g
    }

    /// Let go: the held sound fades out quickly.
    func release() {
        fadeOut(active)
        current = nil
    }

    /// Play one grapheme briefly (hint pulses, tile taps).
    func tap(_ grapheme: String, holdFor seconds: Double = 0.5) async {
        hold(grapheme)
        try? await Task.sleep(for: .seconds(seconds))
        release()
    }

    /// Model a stretched blend: each sound held in turn with no gaps.
    func stretch(_ graphemes: [String], perSound: Double = 0.55, onSound: ((Int) -> Void)? = nil) async {
        await prepare(graphemes)
        for (i, g) in graphemes.enumerated() {
            onSound?(i)
            if g.isEmpty {
                try? await Task.sleep(for: .seconds(0.2))
                continue
            }
            hold(g)
            let isStop = !(LetterSounds.table[g.lowercased()]?.continuous ?? true)
            try? await Task.sleep(for: .seconds(isStop ? 0.25 : perSound))
        }
        release()
        onSound?(-1)
    }

    private func fadeOut(_ index: Int) {
        let node = nodes[index]
        fadeTasks[index]?.cancel()
        fadeTasks[index] = Task { [weak self] in
            for step in stride(from: 1.0, through: 0, by: -0.125) {
                node.volume = Float(step)
                try? await Task.sleep(for: .milliseconds(10))
                if Task.isCancelled { return }
            }
            node.stop()
            _ = self
        }
    }

    // MARK: Building sounds

    private func build(_ g: String) async -> Sound? {
        if let recorded = loadRecording(g) { return recorded }
        guard let info = LetterSounds.table[g] else { return nil }
        // Render longer than needed so the steady middle is easy to find.
        let ipa = info.continuous ? info.ipa + "ːːː" : info.ipa
        guard let raw = await render(ipa: ipa, text: g), let pcm = convert(raw) else { return nil }
        return slice(pcm, continuous: info.continuous)
    }

    private func loadRecording(_ g: String) -> Sound? {
        func read(_ name: String) -> AVAudioPCMBuffer? {
            for ext in ["m4a", "wav", "caf", "mp3"] {
                guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Media/phonemes"),
                      let file = try? AVAudioFile(forReading: url),
                      let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
                      (try? file.read(into: buffer)) != nil else { continue }
                return convert(buffer)
            }
            return nil
        }
        if let long = read("\(g)-long") { return Sound(onset: long, loop: long) }
        guard let short = read(g) else { return nil }
        let continuous = LetterSounds.table[g]?.continuous ?? false
        return slice(short, continuous: continuous)
    }

    private func render(ipa: String, text: String) async -> AVAudioPCMBuffer? {
        let attributed = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute): ipa,
        ])
        let utterance = AVSpeechUtterance(attributedString: attributed)
        utterance.voice = voice
        utterance.rate = 0.3
        return await withCheckedContinuation { continuation in
            var chunks: [AVAudioPCMBuffer] = []
            var done = false
            renderer.write(utterance) { buffer in
                guard !done else { return }
                guard let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 else {
                    done = true
                    continuation.resume(returning: Self.join(chunks))
                    return
                }
                chunks.append(pcm)
            }
        }
    }

    nonisolated private static func join(_ chunks: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
        guard let first = chunks.first else { return nil }
        let total = chunks.reduce(0) { $0 + Int($1.frameLength) }
        guard let out = AVAudioPCMBuffer(pcmFormat: first.format, frameCapacity: AVAudioFrameCount(total)) else { return nil }
        let bytesPerFrame = Int(first.format.streamDescription.pointee.mBytesPerFrame)
        var offset = 0
        for chunk in chunks {
            let n = Int(chunk.frameLength)
            let dst = out.audioBufferList.pointee.mBuffers.mData!.advanced(by: offset * bytesPerFrame)
            memcpy(dst, chunk.audioBufferList.pointee.mBuffers.mData!, n * bytesPerFrame)
            offset += n
        }
        out.frameLength = AVAudioFrameCount(total)
        return out
    }

    private func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        if buffer.format == format { return buffer }
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else { return nil }
        let ratio = format.sampleRate / buffer.format.sampleRate
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 4096) else { return nil }
        var fed = false
        _ = converter.convert(to: out, error: nil) { _, status in
            if fed { status.pointee = .endOfStream; return nil }
            fed = true
            status.pointee = .haveData
            return buffer
        }
        return out
    }

    /// Trim silence; for continuous sounds cut an onset plus a seamless loop
    /// from the steady middle.
    private func slice(_ buffer: AVAudioPCMBuffer, continuous: Bool) -> Sound? {
        let data = buffer.floatChannelData![0]
        let n = Int(buffer.frameLength)
        let threshold: Float = 0.02
        guard let start = (0..<n).first(where: { abs(data[$0]) > threshold }),
              let end = (0..<n).last(where: { abs(data[$0]) > threshold }), end > start else { return nil }
        let sr = format.sampleRate
        if !continuous {
            return Sound(onset: copy(buffer, from: start, count: end - start, fadeOutMs: 15), loop: nil)
        }
        let length = end - start
        let loopStart = start + Int(Double(length) * 0.3)
        let loopEnd = start + Int(Double(length) * 0.75)
        let crossfade = Int(sr * 0.025)
        guard loopEnd - loopStart > crossfade * 3 else {
            return Sound(onset: copy(buffer, from: start, count: length, fadeOutMs: 15), loop: nil)
        }
        let onset = copy(buffer, from: start, count: loopStart - start, fadeOutMs: 0)
        // loop = segment with its tail blended over its head so the seam is silent
        let loopLength = loopEnd - loopStart - crossfade
        let loop = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(loopLength))!
        loop.frameLength = AVAudioFrameCount(loopLength)
        let out = loop.floatChannelData![0]
        for i in 0..<loopLength {
            var sample = data[loopStart + i]
            if i < crossfade {
                let w = Float(i) / Float(crossfade)
                sample = sample * w + data[loopStart + loopLength + i] * (1 - w)
            }
            out[i] = sample
        }
        return Sound(onset: onset, loop: loop)
    }

    private func copy(_ buffer: AVAudioPCMBuffer, from start: Int, count: Int, fadeOutMs: Double) -> AVAudioPCMBuffer {
        let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(max(count, 1)))!
        out.frameLength = AVAudioFrameCount(max(count, 1))
        let src = buffer.floatChannelData![0], dst = out.floatChannelData![0]
        let fade = Int(format.sampleRate * fadeOutMs / 1000)
        for i in 0..<count {
            var s = src[start + i]
            if fade > 0, i > count - fade { s *= Float(count - i) / Float(fade) }
            dst[i] = s
        }
        return out
    }
}
