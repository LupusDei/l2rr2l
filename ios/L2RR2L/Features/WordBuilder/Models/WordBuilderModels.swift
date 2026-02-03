import Foundation

/// A word puzzle for the Word Builder game.
struct WordPuzzle: Identifiable, Equatable {
    let id: String
    let word: String
    let emoji: String
    let hint: String

    init(word: String, emoji: String, hint: String) {
        self.id = UUID().uuidString
        self.word = word
        self.emoji = emoji
        self.hint = hint
    }

    /// The letters of the word as an array of characters.
    var letters: [Character] {
        Array(word)
    }

    /// The number of letters in the word.
    var length: Int {
        word.count
    }
}

/// A letter tile in the Word Builder game.
struct WordBuilderTile: Identifiable, Equatable {
    let id: String
    let letter: Character
    var isUsed: Bool

    init(letter: Character, isUsed: Bool = false) {
        self.id = UUID().uuidString
        self.letter = letter
        self.isUsed = isUsed
    }
}

/// Game state for the Word Builder game.
enum WordBuilderState: Equatable {
    case notStarted
    case playing
    case checking
    case correct
    case incorrect
    case gameComplete
}
