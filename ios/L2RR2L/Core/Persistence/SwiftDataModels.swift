import Foundation
import SwiftData

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

    /// Convert from API model
    convenience init(from child: Child, needsSync: Bool = false) {
        self.init(
            id: child.id,
            userId: child.userId,
            name: child.name,
            age: child.age,
            sex: child.sex,
            avatar: child.avatar,
            gradeLevel: child.gradeLevel,
            learningStyle: child.learningStyle,
            interests: child.interests ?? [],
            lastFetched: Date(),
            needsSync: needsSync
        )
    }

    /// Convert to API model
    func toChild() -> Child {
        Child(
            id: id,
            userId: userId,
            name: name,
            age: age,
            sex: sex,
            avatar: avatar,
            gradeLevel: gradeLevel,
            learningStyle: learningStyle,
            interests: interests.isEmpty ? nil : interests
        )
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

    /// Convert from API model
    convenience init(from lesson: Lesson) {
        let activitiesData = (try? JSONEncoder().encode(lesson.activities)) ?? Data()

        self.init(
            id: lesson.id,
            title: lesson.title,
            lessonDescription: lesson.description,
            subject: lesson.subject.rawValue,
            difficulty: lesson.difficulty.rawValue,
            objectives: lesson.objectives,
            activitiesJSON: activitiesData,
            durationMinutes: lesson.durationMinutes,
            prerequisites: lesson.prerequisites ?? [],
            tags: lesson.tags ?? [],
            thumbnailUrl: lesson.thumbnailUrl,
            ageRangeMin: lesson.ageRange?.min,
            ageRangeMax: lesson.ageRange?.max,
            createdAt: lesson.createdAt,
            updatedAt: lesson.updatedAt,
            lastFetched: Date()
        )
    }

    /// Convert to API model
    func toLesson() -> Lesson? {
        guard let subject = LessonSubject(rawValue: subject),
              let difficulty = DifficultyLevel(rawValue: difficulty) else {
            return nil
        }

        let activities = (try? JSONDecoder().decode([LessonActivity].self, from: activitiesJSON)) ?? []
        let ageRange: Lesson.AgeRange? = if let min = ageRangeMin, let max = ageRangeMax {
            Lesson.AgeRange(min: min, max: max)
        } else {
            nil
        }

        return Lesson(
            id: id,
            title: title,
            description: lessonDescription,
            subject: subject,
            difficulty: difficulty,
            objectives: objectives,
            activities: activities,
            durationMinutes: durationMinutes,
            prerequisites: prerequisites.isEmpty ? nil : prerequisites,
            tags: tags.isEmpty ? nil : tags,
            thumbnailUrl: thumbnailUrl,
            ageRange: ageRange,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
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

    /// Convert from API model
    convenience init(from progress: LessonProgress, needsSync: Bool = false) {
        let activityData = (try? JSONEncoder().encode(progress.activityProgress)) ?? Data()

        self.init(
            id: progress.id,
            childId: progress.childId,
            lessonId: progress.lessonId,
            status: progress.status.rawValue,
            currentActivityIndex: progress.currentActivityIndex,
            activityProgressJSON: activityData,
            overallScore: progress.overallScore,
            totalTimeSeconds: progress.totalTimeSeconds,
            startedAt: progress.startedAt,
            completedAt: progress.completedAt,
            needsSync: needsSync,
            lastModified: Date()
        )
    }

    /// Convert to API model
    func toLessonProgress() -> LessonProgress? {
        guard let status = LessonStatus(rawValue: status) else {
            return nil
        }

        let activityProgress = (try? JSONDecoder().decode([ActivityProgress].self, from: activityProgressJSON)) ?? []

        return LessonProgress(
            lessonId: lessonId,
            childId: childId,
            status: status,
            currentActivityIndex: currentActivityIndex,
            activityProgress: activityProgress,
            overallScore: overallScore,
            totalTimeSeconds: totalTimeSeconds,
            startedAt: startedAt,
            completedAt: completedAt
        )
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

    /// Default ID for the single settings record
    static let defaultId = "voice_settings"

    init(
        id: String = LocalVoiceSettings.defaultId,
        voiceId: String = VoiceSettings.default.voiceId,
        stability: Double = VoiceSettings.default.stability,
        similarityBoost: Double = VoiceSettings.default.similarityBoost,
        style: Double = VoiceSettings.default.style,
        speed: Double = VoiceSettings.default.speed,
        useSpeakerBoost: Bool = VoiceSettings.default.useSpeakerBoost,
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

    /// Convert from API model
    convenience init(from settings: VoiceSettings) {
        self.init(
            voiceId: settings.voiceId,
            stability: settings.stability,
            similarityBoost: settings.similarityBoost,
            style: settings.style,
            speed: settings.speed,
            useSpeakerBoost: settings.useSpeakerBoost
        )
    }

    /// Convert to API model
    func toVoiceSettings() -> VoiceSettings {
        VoiceSettings(
            voiceId: voiceId,
            stability: stability,
            similarityBoost: similarityBoost,
            style: style,
            speed: speed,
            useSpeakerBoost: useSpeakerBoost
        )
    }
}

// MARK: - Local Onboarding State

@Model
final class LocalOnboardingState {
    @Attribute(.unique) var id: String
    var isComplete: Bool
    var currentStep: String
    var lastModified: Date

    /// Default ID for the single onboarding record
    static let defaultId = "onboarding_state"

    init(
        id: String = LocalOnboardingState.defaultId,
        isComplete: Bool = false,
        currentStep: String = OnboardingStep.welcome.rawValue,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.isComplete = isComplete
        self.currentStep = currentStep
        self.lastModified = lastModified
    }

    /// Get the current step as enum
    var step: OnboardingStep {
        OnboardingStep(rawValue: currentStep) ?? .welcome
    }
}
