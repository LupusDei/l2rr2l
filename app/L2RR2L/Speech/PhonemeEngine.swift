@preconcurrency import AVFoundation

/// Letter sounds that can be *held*: while a finger rests on a tile its sound
/// keeps going (/mmmmm/), and moving to the next tile crossfades into the next
/// sound with no gap. That is what makes Stretchy Blend work.
///
/// Sounds come only from recordings: `Media/phonemes/<g>.wav` (the natural
/// sound) and, for continuous sounds, `<g>-long.wav` (a seamless loop to hold).
/// There is no synthesized fallback; a missing sound is silent and logged.
///
/// Stop sounds (t, p, b, d, k, g...) can't be held; they play once as a pop.
@MainActor
final class PhonemeEngine {
    private struct Sound {
        /// Plays first (for held sounds, the same seamless loop).
        let onset: AVAudioPCMBuffer
        /// Seamless loop for continuous sounds; nil for one-shots (stops,
        /// vowel teams), which always play to the end.
        let loop: AVAudioPCMBuffer?
        var duration: Double { Double(onset.frameLength) / onset.format.sampleRate }
    }

    private let engine = AVAudioEngine()
    /// Two nodes for held sounds so one can fade while the next starts.
    private let holdNodes = [AVAudioPlayerNode(), AVAudioPlayerNode()]
    /// One-shots get their own node and are never cut off by a fade, so a
    /// short /t/ at the end of a slide is always heard in full.
    private let oneShotNode = AVAudioPlayerNode()
    private var active = 0
    private var cache: [String: Sound] = [:]
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var fadeTasks: [Int: Task<Void, Never>] = [:]
    private(set) var current: String?

    init() {
        for node in holdNodes + [oneShotNode] {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
        try? engine.start()
    }

    /// Load the sounds for these graphemes ahead of time.
    func prepare(_ graphemes: [String]) async {
        for g in Set(graphemes.map { $0.lowercased() }) where !g.isEmpty && cache[g] == nil {
            if let sound = await build(g) { cache[g] = sound }
        }
    }

    /// How long a grapheme's one-shot lasts (0 for held sounds or unknown).
    func oneShotDuration(_ grapheme: String) -> Double {
        guard let s = cache[grapheme.lowercased()], s.loop == nil else { return 0 }
        return s.duration
    }

    /// Start (or switch to) a grapheme's sound. Continuous sounds keep going
    /// until `release()` or the next `hold`; one-shots play once, in full.
    func hold(_ grapheme: String) {
        let g = grapheme.lowercased()
        if g.isEmpty { release(); return } // silent letter (magic e)
        guard g != current, let sound = cache[g] else { return }
        if !engine.isRunning { try? engine.start() }
        fadeOut(active)
        current = g
        guard let loop = sound.loop else {
            oneShotNode.stop()
            oneShotNode.volume = 1
            oneShotNode.scheduleBuffer(sound.onset, at: nil, options: [])
            oneShotNode.play()
            return
        }
        active = (active + 1) % holdNodes.count
        let node = holdNodes[active]
        fadeTasks[active]?.cancel()
        node.stop()
        node.volume = 1
        node.scheduleBuffer(loop, at: nil, options: .loops)
        node.play()
    }

    /// Let go: a held sound fades out quickly (one-shots finish on their own).
    func release() {
        fadeOut(active)
        current = nil
    }

    /// Play one grapheme briefly (hint pulses, tile taps).
    func tap(_ grapheme: String, holdFor seconds: Double = 0.5) async {
        hold(grapheme)
        let shot = oneShotDuration(grapheme)
        try? await Task.sleep(for: .seconds(shot > 0 ? shot + 0.05 : seconds))
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
            let shot = oneShotDuration(g)
            try? await Task.sleep(for: .seconds(shot > 0 ? max(shot + 0.06, 0.2) : perSound))
            if shot > 0 { current = nil }
        }
        release()
        onSound?(-1)
    }

    private func fadeOut(_ index: Int) {
        let node = holdNodes[index]
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
        #if DEBUG
        print("🔇 missing letter sound: Media/phonemes/\(g).wav")
        #endif
        return nil
    }

    private func loadRecording(_ g: String) -> Sound? {
        func read(_ name: String) -> AVAudioPCMBuffer? {
            for ext in ["wav", "caf", "m4a", "mp3"] {
                guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Media/phonemes"),
                      let file = try? AVAudioFile(forReading: url),
                      let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
                      (try? file.read(into: buffer)) != nil else { continue }
                return convert(buffer)
            }
            return nil
        }
        // Held sound: the -long take, re-seamed with a crossfade so the loop
        // never clicks (some takes, like s and sh, don't meet exactly).
        if let long = read("\(g)-long"), let loop = seamless(long) {
            return Sound(onset: loop, loop: loop)
        }
        // Everything else plays once, untrimmed apart from silence.
        guard let short = read(g) else { return nil }
        return Sound(onset: trimSilence(short), loop: nil)
    }

    /// Blends the last 40 ms into the first 40 ms so the end meets the start.
    private func seamless(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let n = Int(buffer.frameLength)
        let fade = Int(format.sampleRate * 0.04)
        guard n > fade * 4, let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n - fade)) else { return nil }
        out.frameLength = AVAudioFrameCount(n - fade)
        let src = buffer.floatChannelData![0], dst = out.floatChannelData![0]
        for i in 0..<(n - fade) {
            var sample = src[i]
            if i < fade {
                let w = Float(i) / Float(fade)
                sample = src[i] * w + src[n - fade + i] * (1 - w)
            }
            dst[i] = sample
        }
        return out
    }

    /// Cuts leading/trailing near-silence (very gently, so quiet stops survive).
    private func trimSilence(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        let data = buffer.floatChannelData![0]
        let n = Int(buffer.frameLength)
        let threshold: Float = 0.004
        let start = max(0, ((0..<n).first { abs(data[$0]) > threshold } ?? 0) - 64)
        let end = min(n, ((0..<n).last { abs(data[$0]) > threshold } ?? (n - 1)) + 256)
        guard end > start else { return buffer }
        return copy(buffer, from: start, count: end - start, fadeOutMs: 4)
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
