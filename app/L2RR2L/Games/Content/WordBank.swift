import Foundation

/// A word as the games need it: tiles (graphemes), the sound each tile makes
/// (`sounds`, "" for a silent letter like magic e) and a picture. Pictures are
/// emoji until the art thread draws the word pictures.
struct Word: Hashable, Identifiable, Codable {
    let text: String
    let graphemes: [String]
    var sounds: [String]?
    let picture: String?
    var stage: Int?
    var distractors: [String]?
    var id: String { text }

    init(_ text: String, _ picture: String?, graphemes: [String]? = nil, sounds: [String]? = nil) {
        self.text = text
        self.picture = picture
        self.graphemes = graphemes ?? text.map(String.init)
        self.sounds = sounds
    }

    /// Sound key per tile for `PhonemeEngine` ("" = silent).
    var soundKeys: [String] { sounds ?? graphemes }
    /// Sound keys with silent tiles removed, for modelling a stretch.
    var spokenSounds: [String] { soundKeys.filter { !$0.isEmpty } }
}

/// One picture-choice item: the word plus two picture distractors that
/// differ by one sound where possible (man: map / pan).
struct BlendItem: Identifiable, Hashable {
    let word: Word
    let distractors: [Word]
    var id: String { word.text }
}

/// A Word Machine chain: each word differs from the one before by one sound.
struct WordChain: Identifiable, Hashable {
    let id: String
    let words: [Word]
    /// Extra letters in the tray that aren't needed, to make her listen.
    let distractors: [String]

    var trayLetters: [String] {
        var seen: [String] = []
        for g in words.flatMap(\.graphemes) + distractors where !seen.contains(g) { seen.append(g) }
        return seen.sorted()
    }
}

/// A short decodable sentence with a scene picture and two near-miss scenes.
struct Sentence: Codable, Hashable {
    let text: String
    let picture: String
    let distractors: [String]
}

/// One world in Cutisie's sky (learning path section 4).
struct Stage: Codable, Identifiable {
    let id: Int
    let name: String
    let graphemes: [String]
    let words: [Word]
    let heartWords: [String]
    let chains: [[Word]]
    let sentences: [Sentence]
    let unicornWords: [Word]
}

struct Curriculum: Codable {
    let version: Int
    let stages: [Stage]

    /// Loaded from `Media/content/curriculum.json` (built by tools/make_curriculum.py).
    static let shared: Curriculum = {
        guard let url = Bundle.main.url(forResource: "curriculum", withExtension: "json", subdirectory: "Media/content"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Curriculum.self, from: data) else {
            assertionFailure("curriculum.json missing or invalid")
            return Curriculum(version: 0, stages: [])
        }
        return decoded
    }()

    func stage(_ id: Int) -> Stage? { stages.first { $0.id == id } }

    /// Every word with a picture, for looking up distractor pictures.
    var pictured: [String: Word] {
        var out: [String: Word] = [:]
        for s in stages { for w in s.words + s.chains.flatMap({ $0 }) where w.picture != nil { out[w.text] = w } }
        return out
    }
}

enum WordBank {
    static let pictures = Curriculum.shared.pictured

    static func picture(_ text: String) -> String? { pictures[text]?.picture }

    /// Picture-choice item for a curriculum word, or nil if it can't be pictured.
    static func blendItem(_ word: Word) -> BlendItem? {
        guard word.picture != nil, let names = word.distractors, names.count == 2 else { return nil }
        let distractors = names.map { pictures[$0] ?? Word($0, nil) }
        guard distractors.allSatisfy({ $0.picture != nil }) else { return nil }
        return BlendItem(word: word, distractors: distractors)
    }

    /// Every pictured word taught at or before `stage`.
    static func items(upTo stage: Int) -> [BlendItem] {
        Curriculum.shared.stages.filter { $0.id <= max(stage, 1) }.flatMap(\.words).compactMap(blendItem)
    }

    static func items(in stage: Int) -> [BlendItem] {
        (Curriculum.shared.stage(max(stage, 1))?.words ?? []).compactMap(blendItem)
    }

    /// Stage 1 starter set, used by previews and tests.
    static var stage1Blends: [BlendItem] { items(in: 1) }

    static func chains(for stage: Int) -> [WordChain] {
        let s = max(stage, 1)
        let source = Curriculum.shared.stages.last { $0.id <= s && !$0.chains.isEmpty }
        return (source?.chains ?? []).enumerated().map { i, words in
            let letters = Set(words.flatMap(\.graphemes))
            let extras = ["a", "e", "i", "o", "u", "s", "m", "t", "p"].filter { !letters.contains($0) }.shuffled().prefix(2)
            return WordChain(id: "s\(source?.id ?? s)-\(i)", words: words, distractors: Array(extras))
        }
    }
}
