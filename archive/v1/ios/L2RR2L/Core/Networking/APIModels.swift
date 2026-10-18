import Foundation

// MARK: - Auth Response Models

public struct AuthResponse: Decodable {
    public let user: User
    public let token: String
}

public struct UserResponse: Decodable {
    public let user: User
}

public struct User: Decodable, Identifiable {
    public let id: String
    public let email: String
    public let name: String
    public let createdAt: String?
}

// MARK: - Auth Request Models

public struct LoginRequest: Codable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct RegisterRequest: Codable {
    public let email: String
    public let password: String
    public let name: String

    public init(email: String, password: String, name: String) {
        self.email = email
        self.password = password
        self.name = name
    }
}

// MARK: - Children Response Models

public struct ChildrenResponse: Decodable {
    public let children: [Child]
}

public struct ChildResponse: Decodable {
    public let child: Child
}

public struct Child: Decodable, Identifiable {
    public let id: String
    public let userId: String?
    public let name: String
    public let age: Int?
    public let sex: String?
    public let avatar: String?
    public let gradeLevel: String?
    public let learningStyle: String?
    public let interests: [String]?
    public let createdAt: String?
    public let updatedAt: String?
}

// MARK: - Children Request Models

public struct CreateChildRequest: Codable {
    public let name: String
    public var age: Int?
    public var sex: String?
    public var avatar: String?
    public var gradeLevel: String?
    public var learningStyle: String?
    public var interests: [String]?

    public init(
        name: String,
        age: Int? = nil,
        sex: String? = nil,
        avatar: String? = nil,
        gradeLevel: String? = nil,
        learningStyle: String? = nil,
        interests: [String]? = nil
    ) {
        self.name = name
        self.age = age
        self.sex = sex
        self.avatar = avatar
        self.gradeLevel = gradeLevel
        self.learningStyle = learningStyle
        self.interests = interests
    }
}

public struct UpdateChildRequest: Codable {
    public var name: String?
    public var age: Int?
    public var sex: String?
    public var avatar: String?
    public var gradeLevel: String?
    public var learningStyle: String?
    public var interests: [String]?

    public init(
        name: String? = nil,
        age: Int? = nil,
        sex: String? = nil,
        avatar: String? = nil,
        gradeLevel: String? = nil,
        learningStyle: String? = nil,
        interests: [String]? = nil
    ) {
        self.name = name
        self.age = age
        self.sex = sex
        self.avatar = avatar
        self.gradeLevel = gradeLevel
        self.learningStyle = learningStyle
        self.interests = interests
    }
}

// MARK: - Lessons Response Models

public struct LessonsResponse: Decodable {
    public let lessons: [Lesson]
    public let total: Int
    public let limit: Int
    public let offset: Int
}

public struct LessonResponse: Decodable {
    public let lesson: Lesson
}

public struct SubjectsResponse: Decodable {
    public let subjects: [String]
}

public struct FiltersResponse: Decodable {
    public let subjects: [String]
    public let gradeLevels: [String]
    public let difficulties: [String]
    public let sources: [String]
    public let learningStyles: [String]
    public let ageRange: AgeRange
}

public struct AgeRange: Decodable {
    public let min: Int
    public let max: Int
}

public struct Lesson: Codable, Identifiable {
    public let id: String
    public let title: String
    public let subject: String
    public let description: String?
    public let gradeLevel: String?
    public let difficulty: String?
    public let durationMinutes: Int?
    public let ageMin: Int?
    public let ageMax: Int?
    public let learningStyles: [String]?
    public let interests: [String]?
    public let objectives: [LessonObjective]?
    public let activities: [LessonActivity]?
    public let materials: [String]?
    public let assessmentCriteria: [AssessmentCriterion]?
    public let source: String?
    public let tags: [String]?
    public let isPublished: Bool?
    public let avgRating: Double?
    public let ratingCount: Int?
    public let totalCompletions: Int?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct LessonObjective: Codable {
    public let text: String?
    public let description: String?
}

public struct LessonActivity: Codable {
    public let id: String?
    public let type: String?
    public let title: String?
    public let description: String?
    public let content: ActivityContent?
    public let durationMinutes: Int?
}

public struct ActivityContent: Codable {
    public let text: String?
    public let words: [String]?
    public let questions: [String]?
}

public struct AssessmentCriterion: Codable {
    public let name: String?
    public let description: String?
}

public struct RateLessonResponse: Decodable {
    public let success: Bool
    public let avgRating: Double?
    public let ratingCount: Int?
}

public struct RecommendationsResponse: Decodable {
    public let recommendations: [Lesson]
}

// MARK: - Progress Response Models

public struct ProgressListResponse: Decodable {
    public let progress: [Progress]
}

public struct ProgressResponse: Decodable {
    public let progress: Progress
}

public struct Progress: Decodable, Identifiable {
    public let id: String?
    public let childId: String
    public let lessonId: String
    public let status: String
    public let score: Int?
    public let timeSpent: Int?
    public let currentActivityIndex: Int?
    public let overallScore: Int?
    public let startedAt: String?
    public let completedAt: String?
    public let lessonTitle: String?
    public let subject: String?
    public let createdAt: String?
    public let updatedAt: String?
}

public struct ProgressSummaryResponse: Decodable {
    public let summary: ProgressSummary
}

public struct ProgressSummary: Decodable {
    public let totalLessons: Int?
    public let completedLessons: Int?
    public let inProgressLessons: Int?
    public let averageScore: Double?
    public let totalTimeSpent: Int?
}

public struct StatsResponse: Decodable {
    public let stats: DetailedStats
}

public struct DetailedStats: Decodable {
    public let overall: OverallStats
    public let bySubject: [SubjectStats]
    public let badges: [ApiBadge]
}

public struct OverallStats: Decodable {
    public let totalLessons: Int
    public let completedLessons: Int
    public let inProgressLessons: Int
    public let averageScore: Double?
    public let totalTimeSeconds: Int
}

public struct SubjectStats: Decodable {
    public let subject: String
    public let lessonsStarted: Int
    public let lessonsCompleted: Int
    public let averageScore: Double?
}

public struct ApiBadge: Decodable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
}

public struct RecentActivityResponse: Decodable {
    public let recent: [Progress]
}

public struct ActivitiesProgressResponse: Decodable {
    public let activities: [ActivityProgress]
}

public struct ActivityProgress: Codable, Identifiable, Equatable {
    public let id: String
    public let childId: String
    public let lessonId: String
    public let activityId: String
    public let completed: Bool
    public let score: Int?
    public let attempts: Int
    public let timeSpentSeconds: Int
    public let completedAt: String?
}

// MARK: - Voice Response Models

public struct VoicesResponse: Decodable {
    public let voices: [Voice]
}

public struct Voice: Decodable, Identifiable {
    public let voiceId: String
    public let name: String
    public let category: String?
    public let description: String?
    public let previewUrl: String?
    public let labels: [String: String]?

    public var id: String { voiceId }
}

public struct ApiVoiceSettingsResponse: Decodable {
    public let settings: ChildVoiceSettings
}

public struct ChildVoiceSettings: Decodable {
    public let childId: String
    public let voiceId: String?
    public let speed: Double?
    public let stability: Double?
    public let similarityBoost: Double?
}

// MARK: - Onboarding Response Models

public struct OnboardingResponse: Decodable {
    public let onboarding: Onboarding
}

public struct Onboarding: Decodable {
    public let id: String?
    public let completed: Bool
    public let step: Int
    public let data: [String: AnyCodable]?
}

public struct OnboardingCompleteResponse: Decodable {
    public let completed: Bool
}

// MARK: - Generic Success Response

public struct SuccessResponse: Decodable {
    public let success: Bool
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Decodable {
    public let value: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
}
