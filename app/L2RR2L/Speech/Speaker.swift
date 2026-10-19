import AVFoundation

/// Plays the Star Voice's recorded audio. There is no synthesized speech in
/// the app: every line, word and sound is a recording in one voice (the
/// Runway "Serene" Star Voice).
///
/// - Lines: `Media/voice/<slug>.(m4a|mp3|wav)`, slug from `VoiceSlug.make`
///   (the list to record is `Media/content/voice_lines.json`, built by
///   tools/voice_lines.py)
/// - Words: `Media/words/<word>.m4a`
/// - Letter sounds: `Media/phonemes/<key>.wav` (played by `PhonemeEngine`)
///
/// A missing recording plays nothing (the caption still shows) and is logged
/// in debug builds so it can be recorded.
@MainActor
final class Speaker: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var finished: CheckedContinuation<Void, Never>?
    private(set) var missing: Set<String> = []

    func stop() {
        player?.stop()
        player = nil
        resume()
    }

    var isSpeaking: Bool { player?.isPlaying ?? false }

    /// A narrator line. Returns false if there is no recording for it.
    @discardableResult
    func say(_ text: String) async -> Bool {
        await play(VoiceSlug.make(text), in: "Media/voice", label: text)
    }

    /// A single word, said normally.
    @discardableResult
    func sayWord(_ word: String) async -> Bool {
        await play(word.lowercased(), in: "Media/words", label: word)
    }

    /// Plays a recording and waits for it to finish.
    func play(_ name: String, in folder: String, label: String) async -> Bool {
        guard let url = Self.url(name, in: folder) else {
            #if DEBUG
            if !missing.contains(label) { print("🔇 missing recording: \(folder)/\(name) (\(label))") }
            #endif
            missing.insert(label)
            return false
        }
        stop()
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return false }
        p.delegate = self
        player = p
        await withCheckedContinuation { continuation in
            finished = continuation
            if !p.play() { resume() }
        }
        return true
    }

    static func url(_ name: String, in folder: String) -> URL? {
        for ext in ["m4a", "mp3", "wav", "caf"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: folder) { return url }
        }
        return nil
    }

    static func hasRecording(for text: String) -> Bool { url(VoiceSlug.make(text), in: "Media/voice") != nil }

    private func resume() {
        finished?.resume()
        finished = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.resume() }
    }
}

/// File name for a narrator line: lowercase words joined by underscores,
/// e.g. "Touch each sound." -> "touch_each_sound". tools/voice_lines.py uses
/// the same rule.
enum VoiceSlug {
    static func make(_ text: String) -> String {
        var out = ""
        var lastUnderscore = true
        for ch in text.lowercased().replacingOccurrences(of: "'", with: "") {
            if ch.isLetter || ch.isNumber, ch.isASCII {
                out.append(ch)
                lastUnderscore = false
            } else if !lastUnderscore {
                out.append("_")
                lastUnderscore = true
            }
        }
        while out.hasSuffix("_") { out.removeLast() }
        return String(out.prefix(80))
    }
}

/// Pure letter sounds as IPA. `continuous` sounds can be held (mmm, sss, aaa);
/// stop sounds (b, t, k) can't, which is why blending games stretch only some.
enum LetterSounds {
    struct Sound { let ipa: String; let continuous: Bool }

    static let table: [String: Sound] = [
        "a": .init(ipa: "æ", continuous: true),
        "b": .init(ipa: "b", continuous: false),
        "c": .init(ipa: "k", continuous: false),
        "d": .init(ipa: "d", continuous: false),
        "e": .init(ipa: "ɛ", continuous: true),
        "f": .init(ipa: "f", continuous: true),
        "g": .init(ipa: "ɡ", continuous: false),
        "h": .init(ipa: "h", continuous: false),
        "i": .init(ipa: "ɪ", continuous: true),
        "j": .init(ipa: "dʒ", continuous: false),
        "k": .init(ipa: "k", continuous: false),
        "l": .init(ipa: "l", continuous: true),
        "m": .init(ipa: "m", continuous: true),
        "n": .init(ipa: "n", continuous: true),
        "o": .init(ipa: "ɑ", continuous: true),
        "p": .init(ipa: "p", continuous: false),
        "qu": .init(ipa: "kw", continuous: false),
        "r": .init(ipa: "ɹ", continuous: true),
        "s": .init(ipa: "s", continuous: true),
        "t": .init(ipa: "t", continuous: false),
        "u": .init(ipa: "ʌ", continuous: true),
        "v": .init(ipa: "v", continuous: true),
        "w": .init(ipa: "w", continuous: true),
        "x": .init(ipa: "ks", continuous: false),
        "y": .init(ipa: "j", continuous: true),
        "z": .init(ipa: "z", continuous: true),
        "sh": .init(ipa: "ʃ", continuous: true),
        "ch": .init(ipa: "tʃ", continuous: false),
        "th": .init(ipa: "θ", continuous: true),
        "ck": .init(ipa: "k", continuous: false),
        "ng": .init(ipa: "ŋ", continuous: true),
        "nk": .init(ipa: "ŋk", continuous: false),
        "wh": .init(ipa: "w", continuous: true),
        "th_v": .init(ipa: "ð", continuous: true),
        "ff": .init(ipa: "f", continuous: true),
        "ll": .init(ipa: "l", continuous: true),
        "ss": .init(ipa: "s", continuous: true),
        // magic e: the vowel says its name
        "a_e": .init(ipa: "eɪ", continuous: true),
        "e_e": .init(ipa: "i", continuous: true),
        "i_e": .init(ipa: "aɪ", continuous: true),
        "o_e": .init(ipa: "oʊ", continuous: true),
        "u_e": .init(ipa: "ju", continuous: true),
        // vowel teams and bossy r
        "ee": .init(ipa: "i", continuous: true),
        "ea": .init(ipa: "i", continuous: true),
        "ai": .init(ipa: "eɪ", continuous: true),
        "ay": .init(ipa: "eɪ", continuous: true),
        "oa": .init(ipa: "oʊ", continuous: true),
        "ow": .init(ipa: "oʊ", continuous: true),
        "ow_cow": .init(ipa: "aʊ", continuous: true),
        "igh": .init(ipa: "aɪ", continuous: true),
        "oo": .init(ipa: "u", continuous: true),
        "oo_book": .init(ipa: "ʊ", continuous: true),
        "ou": .init(ipa: "aʊ", continuous: true),
        "oi": .init(ipa: "ɔɪ", continuous: true),
        "oy": .init(ipa: "ɔɪ", continuous: true),
        "ar": .init(ipa: "ɑɹ", continuous: true),
        "or": .init(ipa: "ɔɹ", continuous: true),
        "er": .init(ipa: "ɝ", continuous: true),
        "ir": .init(ipa: "ɝ", continuous: true),
        "ur": .init(ipa: "ɝ", continuous: true),
        "y_i": .init(ipa: "aɪ", continuous: true),
        "y_e": .init(ipa: "i", continuous: true),
    ]
}
