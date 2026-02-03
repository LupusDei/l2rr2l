import Foundation
import SwiftData

/// Service for managing local data persistence using SwiftData.
/// Provides offline-first data access with sync tracking.
@MainActor
public final class PersistenceService: ObservableObject {
    public static let shared = PersistenceService()

    let modelContainer: ModelContainer
    private var modelContext: ModelContext

    private init() {
        do {
            let schema = Schema([
                CachedChild.self,
                CachedLesson.self,
                LocalProgress.self,
                LocalVoiceSettings.self,
                LocalOnboardingState.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// For testing with in-memory storage
    init(inMemory: Bool) {
        do {
            let schema = Schema([
                CachedChild.self,
                CachedLesson.self,
                LocalProgress.self,
                LocalVoiceSettings.self,
                LocalOnboardingState.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                allowsSave: true
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Child Profiles

    /// Save or update a child profile
    func saveChild(_ child: Child, needsSync: Bool = false) throws {
        let descriptor = FetchDescriptor<CachedChild>(
            predicate: #Predicate { $0.id == child.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.userId = child.userId
            existing.name = child.name
            existing.age = child.age
            existing.sex = child.sex
            existing.avatar = child.avatar
            existing.gradeLevel = child.gradeLevel
            existing.learningStyle = child.learningStyle
            existing.interests = child.interests ?? []
            existing.lastFetched = Date()
            existing.needsSync = needsSync
        } else {
            let cached = CachedChild(from: child, needsSync: needsSync)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    /// Get a child by ID
    func getChild(id: String) throws -> Child? {
        let descriptor = FetchDescriptor<CachedChild>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toChild()
    }

    /// Get all cached children for a user
    func getChildren(userId: String) throws -> [Child] {
        let descriptor = FetchDescriptor<CachedChild>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toChild() }
    }

    /// Get children that need syncing
    func getChildrenNeedingSync() throws -> [Child] {
        let descriptor = FetchDescriptor<CachedChild>(
            predicate: #Predicate { $0.needsSync == true }
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toChild() }
    }

    /// Mark a child as synced
    func markChildSynced(id: String) throws {
        let descriptor = FetchDescriptor<CachedChild>(
            predicate: #Predicate { $0.id == id }
        )
        if let cached = try modelContext.fetch(descriptor).first {
            cached.needsSync = false
            try modelContext.save()
        }
    }

    /// Delete a child profile
    func deleteChild(id: String) throws {
        let descriptor = FetchDescriptor<CachedChild>(
            predicate: #Predicate { $0.id == id }
        )
        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    // MARK: - Lessons

    /// Save or update a lesson
    func saveLesson(_ lesson: Lesson) throws {
        let descriptor = FetchDescriptor<CachedLesson>(
            predicate: #Predicate { $0.id == lesson.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            let updated = CachedLesson(from: lesson)
            existing.title = updated.title
            existing.lessonDescription = updated.lessonDescription
            existing.subject = updated.subject
            existing.difficulty = updated.difficulty
            existing.objectives = updated.objectives
            existing.activitiesJSON = updated.activitiesJSON
            existing.durationMinutes = updated.durationMinutes
            existing.prerequisites = updated.prerequisites
            existing.tags = updated.tags
            existing.thumbnailUrl = updated.thumbnailUrl
            existing.ageRangeMin = updated.ageRangeMin
            existing.ageRangeMax = updated.ageRangeMax
            existing.createdAt = updated.createdAt
            existing.updatedAt = updated.updatedAt
            existing.lastFetched = Date()
        } else {
            let cached = CachedLesson(from: lesson)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    /// Save multiple lessons
    func saveLessons(_ lessons: [Lesson]) throws {
        for lesson in lessons {
            try saveLesson(lesson)
        }
    }

    /// Get a lesson by ID
    func getLesson(id: String) throws -> Lesson? {
        let descriptor = FetchDescriptor<CachedLesson>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toLesson()
    }

    /// Get all cached lessons
    func getAllLessons() throws -> [Lesson] {
        let descriptor = FetchDescriptor<CachedLesson>(
            sortBy: [SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toLesson() }
    }

    /// Get lessons by subject
    func getLessons(subject: LessonSubject) throws -> [Lesson] {
        let subjectRaw = subject.rawValue
        let descriptor = FetchDescriptor<CachedLesson>(
            predicate: #Predicate { $0.subject == subjectRaw },
            sortBy: [SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toLesson() }
    }

    /// Get lessons by difficulty
    func getLessons(difficulty: DifficultyLevel) throws -> [Lesson] {
        let difficultyRaw = difficulty.rawValue
        let descriptor = FetchDescriptor<CachedLesson>(
            predicate: #Predicate { $0.difficulty == difficultyRaw },
            sortBy: [SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toLesson() }
    }

    /// Delete a lesson
    func deleteLesson(id: String) throws {
        let descriptor = FetchDescriptor<CachedLesson>(
            predicate: #Predicate { $0.id == id }
        )
        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// Clear all cached lessons
    func clearLessons() throws {
        let descriptor = FetchDescriptor<CachedLesson>()
        let lessons = try modelContext.fetch(descriptor)
        for lesson in lessons {
            modelContext.delete(lesson)
        }
        try modelContext.save()
    }

    // MARK: - Progress

    /// Save or update progress
    func saveProgress(_ progress: LessonProgress, needsSync: Bool = false) throws {
        let progressId = progress.id
        let descriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.id == progressId }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            let updated = LocalProgress(from: progress, needsSync: needsSync)
            existing.status = updated.status
            existing.currentActivityIndex = updated.currentActivityIndex
            existing.activityProgressJSON = updated.activityProgressJSON
            existing.overallScore = updated.overallScore
            existing.totalTimeSeconds = updated.totalTimeSeconds
            existing.startedAt = updated.startedAt
            existing.completedAt = updated.completedAt
            existing.needsSync = needsSync || existing.needsSync
            existing.lastModified = Date()
        } else {
            let cached = LocalProgress(from: progress, needsSync: needsSync)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    /// Get progress for a specific lesson and child
    func getProgress(childId: String, lessonId: String) throws -> LessonProgress? {
        let descriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.childId == childId && $0.lessonId == lessonId }
        )
        return try modelContext.fetch(descriptor).first?.toLessonProgress()
    }

    /// Get all progress for a child
    func getAllProgress(childId: String) throws -> [LessonProgress] {
        let descriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.childId == childId },
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toLessonProgress() }
    }

    /// Get progress that needs syncing
    func getProgressNeedingSync() throws -> [LessonProgress] {
        let descriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.needsSync == true }
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toLessonProgress() }
    }

    /// Mark progress as synced
    func markProgressSynced(id: String) throws {
        let descriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.id == id }
        )
        if let cached = try modelContext.fetch(descriptor).first {
            cached.needsSync = false
            try modelContext.save()
        }
    }

    /// Delete progress
    func deleteProgress(id: String) throws {
        let descriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.id == id }
        )
        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// Clear all progress for a child
    func clearProgress(childId: String) throws {
        let descriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.childId == childId }
        )
        let progress = try modelContext.fetch(descriptor)
        for p in progress {
            modelContext.delete(p)
        }
        try modelContext.save()
    }

    // MARK: - Voice Settings

    /// Save voice settings
    func saveVoiceSettings(_ settings: VoiceSettings) throws {
        let settingsId = LocalVoiceSettings.defaultId
        let descriptor = FetchDescriptor<LocalVoiceSettings>(
            predicate: #Predicate { $0.id == settingsId }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.voiceId = settings.voiceId
            existing.stability = settings.stability
            existing.similarityBoost = settings.similarityBoost
            existing.style = settings.style
            existing.speed = settings.speed
            existing.useSpeakerBoost = settings.useSpeakerBoost
            existing.lastModified = Date()
        } else {
            let local = LocalVoiceSettings(from: settings)
            modelContext.insert(local)
        }

        try modelContext.save()
    }

    /// Get voice settings
    func getVoiceSettings() throws -> VoiceSettings {
        let settingsId = LocalVoiceSettings.defaultId
        let descriptor = FetchDescriptor<LocalVoiceSettings>(
            predicate: #Predicate { $0.id == settingsId }
        )
        return try modelContext.fetch(descriptor).first?.toVoiceSettings() ?? .default
    }

    // MARK: - Onboarding State

    /// Save onboarding state
    func saveOnboardingState(isComplete: Bool, currentStep: OnboardingStep) throws {
        let stateId = LocalOnboardingState.defaultId
        let descriptor = FetchDescriptor<LocalOnboardingState>(
            predicate: #Predicate { $0.id == stateId }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.isComplete = isComplete
            existing.currentStep = currentStep.rawValue
            existing.lastModified = Date()
        } else {
            let state = LocalOnboardingState(
                isComplete: isComplete,
                currentStep: currentStep.rawValue
            )
            modelContext.insert(state)
        }

        try modelContext.save()
    }

    /// Get onboarding state
    func getOnboardingState() throws -> (isComplete: Bool, currentStep: OnboardingStep) {
        let stateId = LocalOnboardingState.defaultId
        let descriptor = FetchDescriptor<LocalOnboardingState>(
            predicate: #Predicate { $0.id == stateId }
        )

        if let state = try modelContext.fetch(descriptor).first {
            return (state.isComplete, state.step)
        }
        return (false, .welcome)
    }

    /// Reset onboarding state
    func resetOnboardingState() throws {
        let stateId = LocalOnboardingState.defaultId
        let descriptor = FetchDescriptor<LocalOnboardingState>(
            predicate: #Predicate { $0.id == stateId }
        )
        if let state = try modelContext.fetch(descriptor).first {
            modelContext.delete(state)
            try modelContext.save()
        }
    }

    // MARK: - Sync Support

    /// Get count of items needing sync
    func getPendingSyncCount() throws -> Int {
        let childDescriptor = FetchDescriptor<CachedChild>(
            predicate: #Predicate { $0.needsSync == true }
        )
        let progressDescriptor = FetchDescriptor<LocalProgress>(
            predicate: #Predicate { $0.needsSync == true }
        )

        let childCount = try modelContext.fetchCount(childDescriptor)
        let progressCount = try modelContext.fetchCount(progressDescriptor)

        return childCount + progressCount
    }

    // MARK: - Cleanup

    /// Clear all local data
    func clearAllData() throws {
        try clearLessons()

        let childDescriptor = FetchDescriptor<CachedChild>()
        let children = try modelContext.fetch(childDescriptor)
        for child in children {
            modelContext.delete(child)
        }

        let progressDescriptor = FetchDescriptor<LocalProgress>()
        let progress = try modelContext.fetch(progressDescriptor)
        for p in progress {
            modelContext.delete(p)
        }

        let settingsId = LocalVoiceSettings.defaultId
        let settingsDescriptor = FetchDescriptor<LocalVoiceSettings>(
            predicate: #Predicate { $0.id == settingsId }
        )
        if let settings = try modelContext.fetch(settingsDescriptor).first {
            modelContext.delete(settings)
        }

        try resetOnboardingState()
        try modelContext.save()
    }
}
