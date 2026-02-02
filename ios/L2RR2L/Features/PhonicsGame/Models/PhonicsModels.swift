import Foundation

/// A phonics word with its sound and metadata
struct PhonicsWord: Identifiable, Codable, Equatable {
    let id: String
    let word: String
    let beginningSound: String
    let phonemes: [String]
    let difficulty: Int
    let image: String
    let emoji: String
    let audio: String
    let category: String
}

/// An answer option in the phonics game
struct SoundOption: Identifiable, Equatable {
    let id: String
    let sound: String
    let isCorrect: Bool

    init(sound: String, isCorrect: Bool) {
        self.id = UUID().uuidString
        self.sound = sound
        self.isCorrect = isCorrect
    }
}

/// Position of the sound to identify
enum SoundPosition: String, CaseIterable {
    case beginning
    case ending

    var displayText: String {
        switch self {
        case .beginning: return "beginning"
        case .ending: return "ending"
        }
    }

    var prompt: String {
        switch self {
        case .beginning: return "What sound does this word START with?"
        case .ending: return "What sound does this word END with?"
        }
    }
}

/// Game state
enum PhonicsGameState: Equatable {
    case notStarted
    case playing
    case roundComplete(correct: Bool)
    case gameComplete
}
