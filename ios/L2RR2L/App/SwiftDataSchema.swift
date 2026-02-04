import Foundation
import SwiftData

// MARK: - SwiftData Models for L2RR2L Persistence

// These models mirror the Core models and provide local persistence
// using SwiftData. The models support offline access and sync tracking.

// MARK: - Cached Child Profile

@Model
final class CachedChild {
    @Attribute(.unique) var id: String
    var userId: String
    var name: String
    var age: Int?
    var sex: String?
    var avatar: String?
    var gradeLevel: String?
    var learningStyle: String?
    var interests: [String]
    var lastFetched: Date
    var needsSync: Bool

    init(
        id: String,
        userId: String,
        name: String,
        age: Int? = nil,
        sex: String? = nil,
        avatar: String? = nil,
        gradeLevel: String? = nil,
        learningStyle: String? = nil,
        interests: [String] = [],
        lastFetched: Date = Date(),
        needsSync: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.age = age
        self.sex = sex
        self.avatar = avatar
        self.gradeLevel = gradeLevel
        self.learningStyle = learningStyle
        self.interests = interests
        self.lastFetched = lastFetched
        self.needsSync = needsSync
    }
}

// MARK: - Cached Lesson

@Model
final class CachedLesson {
    @Attribute(.unique) var id: String
    var title: String
    var lessonDescription: String
    var subject: String
    var difficulty: String
    var objectives: [String]
    var activitiesJSON: Data
    var durationMinutes: Int
    var prerequisites: [String]
    var tags: [String]
    var thumbnailUrl: String?
    var ageRangeMin: Int?
    var ageRangeMax: Int?
    var createdAt: String
    var updatedAt: String
    var lastFetched: Date

    init(
        id: String,
        title: String,
        lessonDescription: String,
        subject: String,
        difficulty: String,
        objectives: [String] = [],
        activitiesJSON: Data = Data(),
        durationMinutes: Int = 0,
        prerequisites: [String] = [],
        tags: [String] = [],
        thumbnailUrl: String? = nil,
        ageRangeMin: Int? = nil,
        ageRangeMax: Int? = nil,
        createdAt: String = "",
        updatedAt: String = "",
        lastFetched: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.lessonDescription = lessonDescription
        self.subject = subject
        self.difficulty = difficulty
        self.objectives = objectives
        self.activitiesJSON = activitiesJSON
        self.durationMinutes = durationMinutes
        self.prerequisites = prerequisites
        self.tags = tags
        self.thumbnailUrl = thumbnailUrl
        self.ageRangeMin = ageRangeMin
        self.ageRangeMax = ageRangeMax
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastFetched = lastFetched
    }
}

// MARK: - Local Progress

@Model
final class LocalProgress {
    @Attribute(.unique) var id: String
    var childId: String
    var lessonId: String
    var status: String
    var currentActivityIndex: Int
    var activityProgressJSON: Data
    var overallScore: Int?
    var totalTimeSeconds: Int
    var startedAt: String
    var completedAt: String?
    var needsSync: Bool
    var lastModified: Date

    init(
        id: String,
        childId: String,
        lessonId: String,
        status: String,
        currentActivityIndex: Int = 0,
        activityProgressJSON: Data = Data(),
        overallScore: Int? = nil,
        totalTimeSeconds: Int = 0,
        startedAt: String = "",
        completedAt: String? = nil,
        needsSync: Bool = false,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.lessonId = lessonId
        self.status = status
        self.currentActivityIndex = currentActivityIndex
        self.activityProgressJSON = activityProgressJSON
        self.overallScore = overallScore
        self.totalTimeSeconds = totalTimeSeconds
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.needsSync = needsSync
        self.lastModified = lastModified
    }
}

// MARK: - Local Voice Settings

@Model
final class LocalVoiceSettings {
    @Attribute(.unique) var id: String
    var voiceId: String
    var stability: Double
    var similarityBoost: Double
    var style: Double
    var speed: Double
    var useSpeakerBoost: Bool
    var lastModified: Date

    static let defaultId = "voice_settings"

    init(
        id: String = LocalVoiceSettings.defaultId,
        voiceId: String = "pMsXgVXv3BLzUgSXRplE",
        stability: Double = 0.5,
        similarityBoost: Double = 0.75,
        style: Double = 0,
        speed: Double = 1.0,
        useSpeakerBoost: Bool = true,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.voiceId = voiceId
        self.stability = stability
        self.similarityBoost = similarityBoost
        self.style = style
        self.speed = speed
        self.useSpeakerBoost = useSpeakerBoost
        self.lastModified = lastModified
    }
}

// MARK: - Local Onboarding State

@Model
final class LocalOnboardingState {
    @Attribute(.unique) var id: String
    var isComplete: Bool
    var currentStep: String
    var lastModified: Date

    static let defaultId = "onboarding_state"

    init(
        id: String = LocalOnboardingState.defaultId,
        isComplete: Bool = false,
        currentStep: String = "welcome",
        lastModified: Date = Date()
    ) {
        self.id = id
        self.isComplete = isComplete
        self.currentStep = currentStep
        self.lastModified = lastModified
    }
}
