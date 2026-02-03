import Foundation

/// A puzzle word with emoji hint for the Word Builder game
struct WordPuzzle: Identifiable, Equatable {
    let id: String
    let word: String
    let emoji: String
    let hint: String

    init(word: String, emoji: String, hint: String = "") {
        self.id = UUID().uuidString
        self.word = word
        self.emoji = emoji
        self.hint = hint.isEmpty ? "Spell the word!" : hint
    }

    /// The letters of the word as an array of characters
    var letters: [Character] {
        Array(word)
    }

    /// The number of letters in the word
    var length: Int {
        word.count
    }
}

/// Game state for the Word Builder game
enum WordBuilderGameState: Equatable {
    case notStarted
    case playing
    case checking
    case correct
    case incorrect
    case gameComplete
}
