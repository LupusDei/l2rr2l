import Foundation

// MARK: - Lesson Enums (used by Views)

public enum LessonSubject: String, Codable, CaseIterable {
    case phonics
    case spelling
    case sightWords = "sight-words"
    case reading
    case wordFamilies = "word-families"
    case vocabulary
    case comprehension
}

public enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

public enum ActivityType: String, Codable, CaseIterable {
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

// MARK: - Lesson Status

public enum LessonStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed
}

// MARK: - Lesson Progress

public struct LessonProgress: Codable, Identifiable, Equatable {
    public let id: String
    public let childId: String
    public let lessonId: String
    public let status: LessonStatus
    public let currentActivityIndex: Int
    public let activityProgress: [ActivityProgress]?
    public let overallScore: Int?
    public let totalTimeSeconds: Int
    public let startedAt: String?
    public let completedAt: String?

    public init(
        id: String = UUID().uuidString,
        childId: String = "",
        lessonId: String = "",
        status: LessonStatus = .notStarted,
        currentActivityIndex: Int = 0,
        activityProgress: [ActivityProgress]? = nil,
        overallScore: Int? = nil,
        totalTimeSeconds: Int = 0,
        startedAt: String? = nil,
        completedAt: String? = nil
    ) {
        self.id = id
        self.childId = childId
        self.lessonId = lessonId
        self.status = status
        self.currentActivityIndex = currentActivityIndex
        self.activityProgress = activityProgress
        self.overallScore = overallScore
        self.totalTimeSeconds = totalTimeSeconds
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    // Convenience init with lessonId first (for compatibility)
    public init(
        lessonId: String,
        childId: String,
        status: LessonStatus = .notStarted,
        currentActivityIndex: Int = 0,
        activityProgress: [ActivityProgress]? = nil,
        overallScore: Int? = nil,
        totalTimeSeconds: Int = 0,
        startedAt: String? = nil,
        completedAt: String? = nil
    ) {
        self.id = UUID().uuidString
        self.childId = childId
        self.lessonId = lessonId
        self.status = status
        self.currentActivityIndex = currentActivityIndex
        self.activityProgress = activityProgress
        self.overallScore = overallScore
        self.totalTimeSeconds = totalTimeSeconds
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

// MARK: - Learning Stats

public struct LearningStats: Codable, Equatable {
    public let totalLessonsStarted: Int
    public let totalLessonsCompleted: Int
    public let averageScore: Double?
    public let totalTimeMinutes: Int
    public let streakDays: Int
    public let bySubject: [SubjectProgress]

    public init(
        totalLessonsStarted: Int = 0,
        totalLessonsCompleted: Int = 0,
        averageScore: Double? = nil,
        totalTimeMinutes: Int = 0,
        streakDays: Int = 0,
        bySubject: [SubjectProgress] = []
    ) {
        self.totalLessonsStarted = totalLessonsStarted
        self.totalLessonsCompleted = totalLessonsCompleted
        self.averageScore = averageScore
        self.totalTimeMinutes = totalTimeMinutes
        self.streakDays = streakDays
        self.bySubject = bySubject
    }
}

public struct SubjectProgress: Codable, Equatable {
    public let subject: String
    public let lessonsCompleted: Int
    public let averageScore: Double?

    public init(subject: String, lessonsCompleted: Int = 0, averageScore: Double? = nil) {
        self.subject = subject
        self.lessonsCompleted = lessonsCompleted
        self.averageScore = averageScore
    }
}
