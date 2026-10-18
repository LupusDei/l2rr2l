@preconcurrency import AVFoundation

/// The app's sound palette. Every effect is synthesized at launch so the app
/// sounds alive with zero asset files; dropping `Media/sfx/<name>.(wav|m4a|caf|mp3)`
/// into the bundle replaces the synth version with the real recording.
enum SoundEffect: String, CaseIterable {
    case tap, pick, drop, correct, oops, star, sticker, fanfare, whoosh, pop, squeak
}

@MainActor
final class SoundEffects {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var twinkles: [AVAudioPCMBuffer] = []
    private var twinkleIndex = 0
    private var lastTwinkle = Date.distantPast
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    var isMuted = false

    init() {
        for _ in 0..<8 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }
        engine.mainMixerNode.outputVolume = 0.8
        for effect in SoundEffect.allCases {
            buffers[effect] = Self.bundled(effect, format: format) ?? Synth.render(effect, format: format)
        }
        // C major pentatonic, two octaves: taps on the sky play a little tune.
        twinkles = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0, 2349.3, 2637.0]
            .map { Synth.twinkle(freq: $0, format: format) }
        try? engine.start()
    }

    /// Next note of the sky's pentatonic run; resets to the bottom after a pause.
    func playTwinkle() {
        guard !isMuted else { return }
        if Date().timeIntervalSince(lastTwinkle) > 1.5 { twinkleIndex = 0 }
        lastTwinkle = Date()
        schedule(twinkles[twinkleIndex % twinkles.count])
        twinkleIndex += 1
    }

    func play(_ effect: SoundEffect) {
        guard !isMuted, let buffer = buffers[effect] else { return }
        schedule(buffer)
    }

    private func schedule(_ buffer: AVAudioPCMBuffer) {
        if !engine.isRunning { try? engine.start() }
        let node = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        node.play()
    }

    /// Sounds from Cutisie's art pack (`Media/cutisie-sfx`) used for app effects.
    private static let packNames: [SoundEffect: String] = [
        .correct: "success_chime", .oops: "try_again_boop", .star: "star_catch",
        .sticker: "level_up", .fanfare: "firework_big", .whoosh: "swoosh_in",
        .squeak: "squeak_happy",
    ]

    private static func bundled(_ effect: SoundEffect, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        var candidates = [(effect.rawValue, "Media/sfx")]
        if let pack = packNames[effect] { candidates.append((pack, "Media/cutisie-sfx")) }
        for (name, folder) in candidates {
            if let buffer = load(name, folder: folder, format: format) { return buffer }
        }
        return nil
    }

    private static func load(_ name: String, folder: String, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        for ext in ["wav", "m4a", "caf", "mp3"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: folder),
                  let file = try? AVAudioFile(forReading: url),
                  let src = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
                  (try? file.read(into: src)) != nil
            else { continue }
            return convert(src, to: format)
        }
        return nil
    }

    private static func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if buffer.format == format { return buffer }
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else { return nil }
        let ratio = format.sampleRate / buffer.format.sampleRate
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024) else { return nil }
        var fed = false
        _ = converter.convert(to: out, error: nil) { _, status in
            if fed { status.pointee = .endOfStream; return nil }
            fed = true
            status.pointee = .haveData
            return buffer
        }
        return out
    }
}

/// Little additive synth for bright, toy-like placeholder sounds.
private enum Synth {
    struct Note { var freq: Double; var start: Double; var length: Double; var gain: Double = 0.5; var glideTo: Double? = nil }

    static func twinkle(freq: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        mix([Note(freq: freq, start: 0, length: 0.5, gain: 0.3),
             Note(freq: freq * 2, start: 0.02, length: 0.3, gain: 0.08)], noise: 0, format: format)
    }

    static func render(_ effect: SoundEffect, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let notes: [Note]
        var noise = 0.0
        switch effect {
        case .tap: notes = [Note(freq: 1320, start: 0, length: 0.07, gain: 0.35)]
        case .pick: notes = [Note(freq: 880, start: 0, length: 0.09, gain: 0.35, glideTo: 1320)]
        case .drop: notes = [Note(freq: 520, start: 0, length: 0.14, gain: 0.5, glideTo: 330)]
        case .pop: notes = [Note(freq: 600, start: 0, length: 0.08, gain: 0.5, glideTo: 1400)]
        case .correct:
            notes = [Note(freq: 1046.5, start: 0, length: 0.25),
                     Note(freq: 1318.5, start: 0.09, length: 0.25),
                     Note(freq: 1568.0, start: 0.18, length: 0.45)]
        case .oops:
            notes = [Note(freq: 440, start: 0, length: 0.22, gain: 0.35, glideTo: 392),
                     Note(freq: 392, start: 0.18, length: 0.3, gain: 0.3, glideTo: 349)]
        case .star:
            notes = (0..<6).map { i in Note(freq: 1568 * pow(1.12, Double(i)), start: Double(i) * 0.045, length: 0.3, gain: 0.25) }
        case .sticker:
            notes = [523.25, 659.25, 783.99, 1046.5, 1318.5].enumerated().map { i, f in
                Note(freq: f, start: Double(i) * 0.07, length: 0.5, gain: 0.35)
            }
        case .fanfare:
            let melody: [(Double, Double, Double)] = [(523.25, 0, 0.15), (659.25, 0.15, 0.15), (783.99, 0.3, 0.15), (1046.5, 0.45, 0.6)]
            notes = melody.flatMap { f, s, l in [Note(freq: f, start: s, length: l + 0.2), Note(freq: f / 2, start: s, length: l + 0.2, gain: 0.25)] }
                + (0..<8).map { i in Note(freq: 2093 * pow(1.06, Double(i)), start: 0.5 + Double(i) * 0.04, length: 0.25, gain: 0.12) }
        case .whoosh:
            notes = []
            noise = 0.35
        case .squeak:
            notes = [Note(freq: 1500, start: 0, length: 0.09, gain: 0.3, glideTo: 2300),
                     Note(freq: 2300, start: 0.085, length: 0.12, gain: 0.28, glideTo: 1700)]
        }

        return mix(notes, noise: noise, format: format)
    }

    static func mix(_ notes: [Note], noise: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let duration = max(notes.map { $0.start + $0.length }.max() ?? 0, noise > 0 ? 0.35 : 0) + 0.05
        let frames = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let out = buffer.floatChannelData![0]

        for note in notes {
            var phase = 0.0
            let startFrame = Int(note.start * sampleRate)
            let count = Int(note.length * sampleRate)
            for i in 0..<count where startFrame + i < Int(frames) {
                let progress = Double(i) / Double(count)
                let freq = note.glideTo.map { note.freq + ($0 - note.freq) * progress } ?? note.freq
                phase += 2 * .pi * freq / sampleRate
                let attack = min(1, Double(i) / (0.005 * sampleRate))
                let env = attack * pow(1 - progress, 2.2)
                // sine plus a soft octave partial reads as a little bell
                let sample = sin(phase) + 0.3 * sin(phase * 2) + 0.1 * sin(phase * 3)
                out[startFrame + i] += Float(sample * env * note.gain * 0.5)
            }
        }
        if noise > 0 {
            var last: Float = 0
            for i in 0..<Int(frames) {
                let progress = Double(i) / Double(frames)
                let env = sin(.pi * progress)
                let white = Float.random(in: -1...1)
                let alpha = Float(0.05 + 0.4 * progress) // brightening filter = rising whoosh
                last += alpha * (white - last)
                out[i] += last * Float(env * noise)
            }
        }
        return buffer
    }
}

enum AudioSessionConfigurator {
    /// `.playback` so the ring/silent switch doesn't mute reading audio, mixed
    /// politely with anything else playing.
    static func configure() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
