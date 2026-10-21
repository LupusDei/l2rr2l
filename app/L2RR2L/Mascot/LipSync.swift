import AVFoundation

/// Cutisie's mouth shapes for reading along. Seven drawings cover every sound,
/// so any word (and any word added later) gets a lip-synced Cutisie without
/// a video per word. See `art/cutisie/READER_RIG.md`.
enum Viseme: String, CaseIterable {
    /// Lips together: m, b, p, and at rest.
    case closed
    /// Slightly open, relaxed: l, n, t, d, th, h, r, k, g, er.
    case small
    /// Jaw dropped: a, o, u, ar, igh, ow (cow).
    case open
    /// Wide, teeth showing: e, i, ee, s, z, a_e, y.
    case wide
    /// Rounded lips: oo, o_e, oa, w, wh, or, oy.
    case round
    /// Pushed-out lips: sh, ch, j.
    case pucker
    /// Top teeth on the bottom lip: f, v.
    case teeth

    /// The shape for a sound key (`LetterSounds` / `Word.soundKeys`).
    static func of(_ sound: String) -> Viseme {
        switch sound.lowercased() {
        case "m", "b", "p", "": .closed
        case "a", "o", "u", "ar", "igh", "i_e", "y_i", "ow_cow", "ou": .open
        case "e", "i", "ee", "ea", "e_e", "y_e", "s", "ss", "z", "x", "a_e", "ai", "ay", "y": .wide
        case "oo", "oo_book", "o_e", "oa", "ow", "w", "wh", "qu", "or", "oi", "oy", "u_e": .round
        case "sh", "ch", "j": .pucker
        case "f", "ff", "v": .teeth
        default: .small
        }
    }
}

/// One step of a mouth track: from `time` (seconds into the recording) the
/// mouth shows `viseme`, opened by `open` (0...1).
struct MouthFrame: Equatable {
    let time: Double
    let viseme: Viseme
    let open: Double
}

/// Builds mouth tracks for spoken words from the word's own sounds and its
/// recording's loudness, so Cutisie's mouth matches the Star Voice recording.
///
/// The recording is cut into 1/30 s frames; frames quieter than a floor are
/// "closed", and the word's sounds are spread across the voiced stretch, with
/// vowels getting more time than consonants (as they do in speech).
@MainActor
enum LipSync {
    static let fps = 30.0
    private static var cache: [String: [MouthFrame]] = [:]

    /// Mouth track for a word recording (`Media/words/<word>`). Without a
    /// recording, a paced track for the sounds is returned so she still
    /// mouths the word.
    static func track(for word: Word) -> [MouthFrame] {
        if let hit = cache[word.text] { return hit }
        let sounds = word.spokenSounds.isEmpty ? [word.text] : word.spokenSounds
        let frames: [MouthFrame]
        if let url = Speaker.url(word.text.lowercased(), in: "Media/words"),
           let levels = loudness(url) {
            frames = track(sounds: sounds, levels: levels)
        } else {
            frames = paced(sounds: sounds, duration: 0.25 + 0.16 * Double(sounds.count))
        }
        cache[word.text] = frames
        return frames
    }

    /// Spreads `sounds` over the voiced frames of `levels` (0...1 per frame).
    static func track(sounds: [String], levels: [Double]) -> [MouthFrame] {
        let floor = 0.12
        guard let first = levels.firstIndex(where: { $0 > floor }),
              let last = levels.lastIndex(where: { $0 > floor }), last > first else {
            return paced(sounds: sounds, duration: Double(levels.count) / fps)
        }
        let weights = sounds.map(weight)
        let total = weights.reduce(0, +)
        let span = Double(last - first + 1)
        var bounds: [Double] = []
        var acc = 0.0
        for w in weights {
            acc += w
            bounds.append(Double(first) + span * acc / total)
        }
        var out: [MouthFrame] = []
        for i in levels.indices {
            let level = levels[i]
            let viseme: Viseme
            if i < first || i > last {
                viseme = .closed
            } else {
                let index = bounds.firstIndex { Double(i) < $0 } ?? sounds.count - 1
                viseme = Viseme.of(sounds[index])
            }
            let frame = MouthFrame(time: Double(i) / fps, viseme: viseme, open: min(1, level * 1.4))
            if out.last?.viseme != frame.viseme || abs((out.last?.open ?? 0) - frame.open) > 0.15 {
                out.append(frame)
            }
        }
        out.append(MouthFrame(time: Double(levels.count) / fps, viseme: .closed, open: 0))
        return out
    }

    /// An even track when there's no recording to follow.
    static func paced(sounds: [String], duration: Double) -> [MouthFrame] {
        let weights = sounds.map(weight)
        let total = weights.reduce(0, +)
        var t = 0.0
        var out: [MouthFrame] = []
        for (sound, w) in zip(sounds, weights) {
            out.append(MouthFrame(time: t, viseme: Viseme.of(sound), open: 0.8))
            t += duration * w / total
        }
        out.append(MouthFrame(time: t, viseme: .closed, open: 0))
        return out
    }

    /// Vowels last about twice as long as consonants.
    private static func weight(_ sound: String) -> Double {
        let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
        return sound.contains(where: vowels.contains) ? 2 : 1
    }

    /// Loudness per 1/30 s frame, normalised so the loudest frame is 1.
    static func loudness(_ url: URL) -> [Double]? {
        guard let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil,
              let data = buffer.floatChannelData?[0] else { return nil }
        let n = Int(buffer.frameLength)
        let hop = max(1, Int(file.processingFormat.sampleRate / fps))
        var levels: [Double] = []
        var i = 0
        while i < n {
            let end = min(n, i + hop)
            var sum: Float = 0
            for j in i..<end { sum += data[j] * data[j] }
            levels.append(Double(sqrt(sum / Float(end - i))))
            i = end
        }
        guard let peak = levels.max(), peak > 0 else { return nil }
        return levels.map { $0 / peak }
    }
}
