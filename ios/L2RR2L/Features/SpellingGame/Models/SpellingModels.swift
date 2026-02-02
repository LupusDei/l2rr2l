import Foundation

/// A spelling word with its hint and optional audio
struct SpellingWord: Identifiable, Equatable {
    let id: String
    let word: String
    let hint: String // emoji or description
    let audioUrl: String?

    init(word: String, hint: String, audioUrl: String? = nil) {
        self.id = UUID().uuidString
        self.word = word
        self.hint = hint
        self.audioUrl = audioUrl
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

/// A letter tile that can be placed in drop zones
struct LetterTileModel: Identifiable, Equatable {
    let id: String
    let letter: Character
    var isPlaced: Bool

    init(letter: Character, isPlaced: Bool = false) {
        self.id = UUID().uuidString
        self.letter = letter
        self.isPlaced = isPlaced
    }
}

/// Game state for the spelling game
enum SpellingGameState: Equatable {
    case notStarted
    case playing
    case checking
    case correct
    case incorrect
    case gameComplete
}
