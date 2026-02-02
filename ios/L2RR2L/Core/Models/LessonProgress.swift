import Foundation

// MARK: - Progress Status

enum LessonStatus: String, Codable, CaseIterable {
    case notStarted = "not-started"
    case inProgress = "in-progress"
    case completed
}

// MARK: - Activity Progress

struct ActivityProgress: Codable, Equatable {
    let activityId: String
    let completed: Bool
    let score: Int?
    let attempts: Int
    let timeSpentSeconds: Int
    let completedAt: String?
}

// MARK: - Lesson Progress

struct LessonProgress: Codable, Identifiable, Equatable {
    var id: String { "\(lessonId)-\(childId)" }
    let lessonId: String
    let childId: String
    let status: LessonStatus
    let currentActivityIndex: Int
    let activityProgress: [ActivityProgress]
    let overallScore: Int?
    let totalTimeSeconds: Int
    let startedAt: String
    let completedAt: String?
}

// MARK: - Lesson with Progress

struct LessonWithProgress: Codable, Identifiable, Equatable {
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
    let ageRange: Lesson.AgeRange?
    let createdAt: String
    let updatedAt: String
    let progress: LessonProgress?
}

// MARK: - Learning Stats

struct LearningStats: Codable, Equatable {
    let childId: String
    let totalLessonsStarted: Int
    let totalLessonsCompleted: Int
    let averageScore: Double
    let totalTimeMinutes: Int
    let subjectProgress: [String: SubjectStats]
    let recentActivity: [RecentLessonActivity]

    struct SubjectStats: Codable, Equatable {
        let lessonsCompleted: Int
        let averageScore: Double
    }

    struct RecentLessonActivity: Codable, Equatable {
        let lessonId: String
        let lessonTitle: String
        let status: LessonStatus
        let lastAccessedAt: String
    }
}
