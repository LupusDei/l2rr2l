import Foundation

/// Everything the app remembers about the reader, saved as one JSON file.
/// Shaped for the learning path in the design notes: 8 stages with a placement
/// check and end-of-stage trials, per-word mastery over separate days, spaced
/// review, error-pattern tracking, milestones, and the reward loop (stars,
/// treats for Cutisie, mystery eggs, a sticker word book).
struct ProgressData: Codable, Equatable {
    static let currentVersion = 1
    var version = currentVersion

    // Learning path
    var stage = 1
    var placementDone = false
    var stageTrialsPassed: Set<Int> = []
    var words: [String: WordRecord] = [:]
    /// Tag → count, e.g. "vowel:a-e", "reversal:b-d".
    var errorPatterns: [String: Int] = [:]
    var milestones: Set<String> = []
    /// Per-skill state for prerequisite step-downs (see `SkillGraph`).
    var skills: [String: SkillRecord] = [:]

    // Rewards
    var stars = 0
    var treats = 0
    var treatsFed = 0
    var eggProgress = 0
    var hatched: [String] = []
    var stickers: [Sticker] = []

    // Activity
    var games: [String: GameStats] = [:]
    var daysPlayed: Set<String> = []
}

struct WordRecord: Codable, Equatable {
    var attempts = 0
    var correct = 0
    /// Days (yyyy-MM-dd) the word was read right, with no audio help, quickly.
    var masteryDays: Set<String> = []
    var lastSeen: Date?
    var nextReview: Date?
    var reviewIntervalDays = 0

    var isMastered: Bool { masteryDays.count >= WordRecord.daysToMaster }

    static let daysToMaster = 3
    static let fastReadSeconds: TimeInterval = 3
}

struct GameStats: Codable, Equatable {
    var sessions = 0
    var answers = 0
    var correct = 0
    var stars = 0
    var lastPlayed: Date?
}

/// A word the child has mastered, kept in the sticker word book.
struct Sticker: Codable, Equatable, Identifiable, Hashable {
    var word: String
    var emoji: String
    var earnedAt: Date
    var id: String { word }
    var name: String { word }

    static func forWord(_ word: String, at date: Date = .now) -> Sticker {
        Sticker(word: word, emoji: StickerArt.emoji(for: word), earnedAt: date)
    }
}

enum StickerArt {
    /// Picture for common decodable words; anything else gets a cute random-but-stable one.
    static let known: [String: String] = [
        "cat": "🐱", "dog": "🐶", "sun": "☀️", "bus": "🚌", "hat": "🎩", "pig": "🐷",
        "fox": "🦊", "bed": "🛏️", "cup": "🥤", "bug": "🐛", "hen": "🐔", "map": "🗺️",
        "fish": "🐟", "ship": "🚢", "frog": "🐸", "star": "⭐️", "moon": "🌙", "egg": "🥚",
        "bat": "🦇", "box": "📦", "jam": "🍯", "pen": "🖊️", "web": "🕸️", "nut": "🥜",
    ]
    static let pool = ["🌈", "🦋", "🍭", "🌸", "🎈", "🍓", "🐞", "🪐", "🧁", "🐬", "🌟", "🦄"]

    static func emoji(for word: String) -> String {
        if let e = known[word.lowercased()] { return e }
        let hash = word.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return pool[hash % pool.count]
    }
}
