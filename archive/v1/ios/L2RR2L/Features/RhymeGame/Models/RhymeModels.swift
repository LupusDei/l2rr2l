import Foundation

/// A word used in the rhyme matching game
struct RhymeWord: Identifiable, Equatable {
    let id: String
    let word: String
    let wordFamily: String
    let difficulty: Int
    let image: String
    let emoji: String
    let audio: String
}

/// A distractor word that doesn't rhyme but may be confused with rhyming words
struct RhymeDistractor: Identifiable, Equatable {
    let id: String
    let word: String
    let confusedWith: [String]
    let difficulty: Int
    let emoji: String
}

/// Difficulty level configuration
struct RhymeDifficultyLevel {
    let name: String
    let description: String
    let targetAge: String
}

/// A generated rhyme question for the game
struct RhymeQuestion {
    let targetWord: RhymeWord
    let correctAnswer: RhymeWord
    let distractors: [RhymeOptionItem]
    let allOptions: [RhymeOptionItem]
}

/// A type-erased option that can be either a RhymeWord or RhymeDistractor
enum RhymeOptionItem: Identifiable, Equatable {
    case word(RhymeWord)
    case distractor(RhymeDistractor)

    var id: String {
        switch self {
        case .word(let w): return w.id
        case .distractor(let d): return d.id
        }
    }

    var displayWord: String {
        switch self {
        case .word(let w): return w.word
        case .distractor(let d): return d.word
        }
    }

    var emoji: String {
        switch self {
        case .word(let w): return w.emoji
        case .distractor(let d): return d.emoji
        }
    }

    var difficulty: Int {
        switch self {
        case .word(let w): return w.difficulty
        case .distractor(let d): return d.difficulty
        }
    }

    var isRhymeWord: Bool {
        if case .word = self { return true }
        return false
    }
}

/// Game state for the rhyme game
enum RhymeGameState: Equatable {
    case notStarted
    case playing
    case checking
    case correct
    case incorrect
    case gameComplete
}
