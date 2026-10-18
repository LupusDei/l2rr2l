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
