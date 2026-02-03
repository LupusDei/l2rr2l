import Foundation

/// A word puzzle with its hint
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

    /// The letters of the word as an array of characters
    var letters: [Character] {
        Array(word)
    }

    /// The number of letters in the word
    var length: Int {
        word.count
    }
}

/// Game state for the word builder game
enum WordBuilderGameState: Equatable {
    case notStarted
    case playing
    case checking
    case correct
    case incorrect
    case gameComplete
}
