import AVFoundation

/// Spoken audio for words, letter names and letter sounds.
///
/// Order of preference for anything the child must *hear correctly*:
/// 1. A bundled recording (`Media/phonemes/<key>.m4a`, `Media/words/<word>.m4a`)
/// 2. On-device TTS (best installed English voice, slowed and brightened for kids)
///
/// Letter sounds must be pure (/mmm/, not "muh"), so TTS uses IPA for them, but
/// real recordings are the goal; drop them in and they win automatically.
@MainActor
final class Speaker: NSObject {
    private let synth = AVSpeechSynthesizer()
    private var waiting: [ObjectIdentifier: CheckedContinuation<Void, Never>] = [:]
    private var clipPlayer: AVAudioPlayer?
    private let voice: AVSpeechSynthesisVoice?

    /// 0...1 where AVSpeechUtteranceDefaultSpeechRate is 0.5.
    var rate: Float = 0.42
    var pitch: Float = 1.15

    override init() {
        voice = Self.bestVoice()
        super.init()
        synth.delegate = self
    }

    var isSpeaking: Bool { synth.isSpeaking || (clipPlayer?.isPlaying ?? false) }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        clipPlayer?.stop()
    }

    // MARK: Public API

    /// Encouragement, instructions, mascot lines.
    func say(_ text: String) async {
        await speak(AVSpeechUtterance(string: text))
    }

    /// A word to read: slightly slower, with a beat of space after.
    func sayWord(_ word: String) async {
        if await playClip(named: word.lowercased(), in: "Media/words") { return }
        let u = AVSpeechUtterance(string: word)
        u.rate = rate * 0.85
        u.postUtteranceDelay = 0.15
        await speak(u)
    }

    /// "bee" for b.
    func sayLetterName(_ letter: String) async {
        await speak(AVSpeechUtterance(string: letter.uppercased()))
    }

    /// The pure sound a letter (or digraph like "sh") makes.
    /// `stretched` holds continuous sounds longer, for blending ("mmmaaat").
    func sayLetterSound(_ grapheme: String, stretched: Bool = false) async {
        let key = grapheme.lowercased()
        let clipName = stretched ? "\(key)-long" : key
        if await playClip(named: clipName, in: "Media/phonemes") { return }
        if stretched, await playClip(named: key, in: "Media/phonemes") { return }
        guard let sound = LetterSounds.table[key] else {
            await sayLetterName(grapheme)
            return
        }
        let ipa = stretched && sound.continuous ? sound.ipa + "ːːː" : sound.ipa
        let text = NSAttributedString(string: grapheme, attributes: [
            NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute): ipa
        ])
        let u = AVSpeechUtterance(attributedString: text)
        u.rate = rate * 0.8
        await speak(u)
    }

    /// Sound out then say: "c... a... t... cat!"
    func sayBlend(_ graphemes: [String], word: String) async {
        for g in graphemes { await sayLetterSound(g, stretched: true) }
        try? await Task.sleep(for: .milliseconds(200))
        await sayWord(word)
    }

    // MARK: Internals

    private func speak(_ utterance: AVSpeechUtterance) async {
        utterance.voice = voice
        if utterance.rate == AVSpeechUtteranceDefaultSpeechRate { utterance.rate = rate }
        utterance.pitchMultiplier = pitch
        await withCheckedContinuation { continuation in
            waiting[ObjectIdentifier(utterance)] = continuation
            synth.speak(utterance)
        }
    }

    private func playClip(named name: String, in folder: String) async -> Bool {
        let url = ["m4a", "wav", "mp3", "caf"].lazy
            .compactMap { Bundle.main.url(forResource: name, withExtension: $0, subdirectory: folder) }
            .first
        guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { return false }
        clipPlayer = player
        player.play()
        try? await Task.sleep(for: .seconds(player.duration))
        return true
    }

    private func finish(_ id: ObjectIdentifier) {
        waiting.removeValue(forKey: id)?.resume()
    }

    private static func bestVoice() -> AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        let preferredNames = ["Ava", "Samantha", "Zoe", "Allison", "Susan"]
        let ranked = english.sorted { a, b in
            if a.quality != b.quality { return a.quality.rawValue > b.quality.rawValue }
            if (a.language == "en-US") != (b.language == "en-US") { return a.language == "en-US" }
            let ai = preferredNames.firstIndex { a.name.contains($0) } ?? 99
            let bi = preferredNames.firstIndex { b.name.contains($0) } ?? 99
            return ai < bi
        }
        return ranked.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}

extension Speaker: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
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
    ]
}
