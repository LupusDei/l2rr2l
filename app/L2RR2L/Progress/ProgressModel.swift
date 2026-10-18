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
    /// One collectible per finished session (sky decorations, accessories, friends).
    var collectibles: [String] = []
    var sessionsCompleted = 0
    /// Results of the Sparkle Check and Sky Trials, newest last.
    var assessments: [Assessment] = []

    // Activity
    var games: [String: GameStats] = [:]
    var daysPlayed: Set<String> = []

    init() {}

    /// Tolerant decoding: fields added in later versions fall back to their
    /// defaults instead of wiping saved progress.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? Self.currentVersion
        stage = try c.decodeIfPresent(Int.self, forKey: .stage) ?? 1
        placementDone = try c.decodeIfPresent(Bool.self, forKey: .placementDone) ?? false
        stageTrialsPassed = try c.decodeIfPresent(Set<Int>.self, forKey: .stageTrialsPassed) ?? []
        words = try c.decodeIfPresent([String: WordRecord].self, forKey: .words) ?? [:]
        errorPatterns = try c.decodeIfPresent([String: Int].self, forKey: .errorPatterns) ?? [:]
        milestones = try c.decodeIfPresent(Set<String>.self, forKey: .milestones) ?? []
        skills = try c.decodeIfPresent([String: SkillRecord].self, forKey: .skills) ?? [:]
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        treats = try c.decodeIfPresent(Int.self, forKey: .treats) ?? 0
        treatsFed = try c.decodeIfPresent(Int.self, forKey: .treatsFed) ?? 0
        eggProgress = try c.decodeIfPresent(Int.self, forKey: .eggProgress) ?? 0
        hatched = try c.decodeIfPresent([String].self, forKey: .hatched) ?? []
        stickers = try c.decodeIfPresent([Sticker].self, forKey: .stickers) ?? []
        collectibles = try c.decodeIfPresent([String].self, forKey: .collectibles) ?? []
        sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        assessments = try c.decodeIfPresent([Assessment].self, forKey: .assessments) ?? []
        games = try c.decodeIfPresent([String: GameStats].self, forKey: .games) ?? [:]
        daysPlayed = try c.decodeIfPresent(Set<String>.self, forKey: .daysPlayed) ?? []
    }
}

/// One Sparkle Check or Sky Trial result.
struct Assessment: Codable, Equatable {
    enum Kind: String, Codable { case placement, skyTrial }
    var kind: Kind
    var date: Date
    var stage: Int
    /// Part name → (correct, asked), e.g. "sounds": 20/26.
    var parts: [String: [Int]]
    var passed: Bool
    var shakySounds: [String] = []
}

struct WordRecord: Codable, Equatable {
    var attempts = 0
    var correct = 0
    /// Days (yyyy-MM-dd) the word was read right, with no audio help, quickly.
    var masteryDays: Set<String> = []
    /// Days the word was read right without help (any speed).
    var knownDays: Set<String> = []
    var lastSeen: Date?
    var nextReview: Date?
    var reviewIntervalDays = 0

    var isMastered: Bool { masteryDays.count >= WordRecord.daysToMaster }
    /// Learning path: known = correct without help on 2 different days.
    var isKnown: Bool { knownDays.count >= 2 || isMastered }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        attempts = try c.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        correct = try c.decodeIfPresent(Int.self, forKey: .correct) ?? 0
        masteryDays = try c.decodeIfPresent(Set<String>.self, forKey: .masteryDays) ?? []
        knownDays = try c.decodeIfPresent(Set<String>.self, forKey: .knownDays) ?? []
        lastSeen = try c.decodeIfPresent(Date.self, forKey: .lastSeen)
        nextReview = try c.decodeIfPresent(Date.self, forKey: .nextReview)
        reviewIntervalDays = try c.decodeIfPresent(Int.self, forKey: .reviewIntervalDays) ?? 0
    }

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

/// Things that fill Cutisie's sky home, one per session (learning path 9).
enum Collectibles {
    static let pool = ["🌸", "🎀", "👑", "🌈", "🍄", "🦋", "🌻", "🪐", "🐦", "🌙", "💎", "🎈",
                       "🌷", "🐞", "⭐️", "🫧", "🍓", "🪁", "🌼", "🐚"]
    /// Mystery egg surprises: friends and accessories.
    static let eggSurprises = ["🐣", "🦄", "🐉", "🦊", "🐰", "🐼", "🦉", "🐢", "🐬", "🦚"]
}
