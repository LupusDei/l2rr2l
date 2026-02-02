import Foundation

// MARK: - Lesson Enums

enum LessonSubject: String, Codable, CaseIterable {
    case phonics
    case spelling
    case sightWords = "sight-words"
    case reading
    case wordFamilies = "word-families"
    case vocabulary
    case comprehension
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

enum ActivityType: String, Codable, CaseIterable {
    case reading
    case spelling
    case phonics
    case sightWords = "sight-words"
    case quiz
    case matching
    case fillInBlank = "fill-in-blank"
    case listenRepeat = "listen-repeat"
    case wordBuilding = "word-building"
}

// MARK: - Activity Models

protocol LessonActivityProtocol: Codable, Identifiable {
    var id: String { get }
    var type: ActivityType { get }
    var instructions: String { get }
    var spokenInstructions: String? { get }
    var order: Int { get }
    var points: Int? { get }
}

struct ReadingActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let content: String
    let imageUrl: String?
    let readAloud: Bool?
}

struct SpellingActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let word: String
    let hint: String?
    let audioUrl: String?
}

struct PhonicsActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let sound: String
    let exampleWords: [String]
    let soundPosition: String?
}

struct SightWordsActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let words: [String]
    let showInContext: Bool?
}

struct QuizActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String?
}

struct MatchingActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let pairs: [[String]]
    let matchType: String
}

struct FillInBlankActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let sentence: String
    let answer: String
    let wordBank: [String]?
}

struct ListenRepeatActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let phrase: String
    let checkPronunciation: Bool?
}

struct WordBuildingActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?
    let pattern: String
    let onsets: [String]
    let words: [String]
}

// MARK: - Lesson Activity (Type-Erased)

struct LessonActivity: Codable, Identifiable, Equatable {
    let id: String
    let type: ActivityType
    let instructions: String
    let spokenInstructions: String?
    let order: Int
    let points: Int?

    // Activity-specific fields (optional based on type)
    let content: String?
    let imageUrl: String?
    let readAloud: Bool?
    let word: String?
    let hint: String?
    let audioUrl: String?
    let sound: String?
    let exampleWords: [String]?
    let soundPosition: String?
    let words: [String]?
    let showInContext: Bool?
    let question: String?
    let options: [String]?
    let correctIndex: Int?
    let explanation: String?
    let pairs: [[String]]?
    let matchType: String?
    let sentence: String?
    let answer: String?
    let wordBank: [String]?
    let phrase: String?
    let checkPronunciation: Bool?
    let pattern: String?
    let onsets: [String]?
}

// MARK: - Lesson

struct Lesson: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let subject: LessonSubject
    let difficulty: DifficultyLevel
    let objectives: [String]
    let activities: [LessonActivity]
    let durationMinutes: Int
    let prerequisites: [String]?
    let tags: [String]?
    let thumbnailUrl: String?
    let ageRange: AgeRange?
    let createdAt: String
    let updatedAt: String

    struct AgeRange: Codable, Equatable {
        let min: Int
        let max: Int
    }
}

// MARK: - Lesson List Response

struct LessonListResponse: Codable, Equatable {
    let lessons: [Lesson]
    let total: Int
    let limit: Int
    let offset: Int
}

// MARK: - Lesson Search Filters

struct LessonSearchFilters: Codable {
    var subject: LessonSubject?
    var difficulty: DifficultyLevel?
    var tags: [String]?
    var search: String?
    var limit: Int?
    var offset: Int?
}
