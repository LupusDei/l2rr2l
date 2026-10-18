import Foundation

/// A word as the games need it: its sound-by-sound spelling and a picture.
/// Pictures are emoji until the art thread draws the word pictures.
struct Word: Hashable, Identifiable, Codable {
    let text: String
    let graphemes: [String]
    let picture: String?
    var id: String { text }

    init(_ text: String, _ picture: String?, graphemes: [String]? = nil) {
        self.text = text
        self.picture = picture
        self.graphemes = graphemes ?? text.map(String.init)
    }
}

/// One Stretchy Blend item: the word plus two picture distractors that
/// differ by one sound (man: map / pan).
struct BlendItem: Identifiable, Hashable {
    let word: Word
    let distractors: [Word]
    var id: String { word.text }
}

enum WordBank {
    /// Stage 1 blending words: continuous first sounds before stop sounds,
    /// stops at the end. Every word and distractor has a clear picture.
    static let stage1Blends: [BlendItem] = [
        BlendItem(word: Word("sun", "☀️"), distractors: [Word("run", "🏃"), Word("sub", "🥪")]),
        BlendItem(word: Word("man", "👨"), distractors: [Word("map", "🗺️"), Word("pan", "🍳")]),
        BlendItem(word: Word("fan", "🪭"), distractors: [Word("van", "🚐"), Word("fin", "🦈")]),
        BlendItem(word: Word("map", "🗺️"), distractors: [Word("mop", "🧹"), Word("cap", "🧢")]),
        BlendItem(word: Word("ram", "🐏"), distractors: [Word("ham", "🍖"), Word("jam", "🍯")]),
        BlendItem(word: Word("net", "🥅"), distractors: [Word("nut", "🥜"), Word("jet", "✈️")]),
        BlendItem(word: Word("mug", "☕️"), distractors: [Word("bug", "🐛"), Word("rug", "🧶")]),
        BlendItem(word: Word("leg", "🦵"), distractors: [Word("log", "🪵"), Word("peg", "📌")]),
        BlendItem(word: Word("sad", "😢"), distractors: [Word("mad", "😠"), Word("sap", "🌲")]),
        BlendItem(word: Word("lip", "👄"), distractors: [Word("lid", "🫙"), Word("hip", "🦴")]),
        BlendItem(word: Word("fish", "🐟", graphemes: ["f", "i", "sh"]), distractors: [Word("dish", "🍽️"), Word("fist", "✊")]),
        BlendItem(word: Word("hen", "🐔"), distractors: [Word("pen", "🖊️"), Word("ten", "🔟")]),
        BlendItem(word: Word("cat", "🐱"), distractors: [Word("bat", "🦇"), Word("cap", "🧢")]),
        BlendItem(word: Word("pig", "🐷"), distractors: [Word("pin", "📍"), Word("dig", "⛏️")]),
        BlendItem(word: Word("bus", "🚌"), distractors: [Word("bun", "🍞"), Word("bug", "🐛")]),
    ]
}

/// A Word Machine chain: each word differs from the one before by one sound.
struct WordChain: Identifiable, Hashable {
    let id: String
    let words: [Word]
    /// Extra letters in the tray that aren't needed, to make her listen.
    let distractors: [String]

    /// Every letter the chain needs plus distractors, as single-use stamps.
    var trayLetters: [String] {
        let needed = words.flatMap(\.graphemes)
        var seen: [String] = []
        for g in needed + distractors where !seen.contains(g) { seen.append(g) }
        return seen.sorted()
    }
}

extension WordBank {
    static func picture(_ text: String) -> String? {
        let all = stage1Blends.flatMap { [$0.word] + $0.distractors }
        if let hit = all.first(where: { $0.text == text }) { return hit.picture }
        return extraPictures[text]
    }

    private static let extraPictures: [String: String] = [
        // words with weak pictures (sat, sit, tip...) stay without one; the
        // bubble shows a sparkle and the word is still spoken
        "can": "🥫", "tin": "🥫", "cot": "🛏️", "hot": "🔥", "hop": "🐇",
    ]

    private static func chain(_ id: String, _ texts: [String], distractors: [String]) -> WordChain {
        WordChain(id: id, words: texts.map { Word($0, picture($0)) }, distractors: distractors)
    }

    /// Stage 1-2 chains from spec 3.2: beginning, end, then middle changes.
    static let chains: [WordChain] = [
        chain("short-a", ["mat", "sat", "sad", "mad", "man", "can"], distractors: ["p", "i"]),
        chain("short-i", ["sit", "pit", "pin", "tin", "tip", "lip"], distractors: ["a", "m"]),
        chain("mixed", ["cat", "cot", "hot", "hop", "hip", "hit"], distractors: ["s", "u"]),
    ]
}
