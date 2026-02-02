import Foundation
import SwiftUI

/// ViewModel for managing lesson playback state and progression.
@MainActor
final class LessonPlayerViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var currentActivityIndex: Int = 0
    @Published private(set) var activityScores: [String: Int] = [:]
    @Published private(set) var completedActivityIds: Set<String> = []
    @Published private(set) var isCompleted: Bool = false

    // MARK: - Properties

    let lesson: Lesson
    private let existingProgress: LessonProgress?

    // MARK: - Computed Properties

    var currentActivity: LessonActivity? {
        guard currentActivityIndex >= 0 && currentActivityIndex < lesson.activities.count else {
            return nil
        }
        return sortedActivities[currentActivityIndex]
    }

    var sortedActivities: [LessonActivity] {
        lesson.activities.sorted { $0.order < $1.order }
    }

    var totalActivities: Int {
        lesson.activities.count
    }

    var completedActivities: Int {
        completedActivityIds.count
    }

    var progressFraction: CGFloat {
        guard totalActivities > 0 else { return 0 }
        return CGFloat(completedActivities) / CGFloat(totalActivities)
    }

    var totalScore: Int {
        activityScores.values.reduce(0, +)
    }

    var maxPossibleScore: Int {
        sortedActivities.compactMap { $0.points }.reduce(0, +)
    }

    var scorePercentage: Int {
        guard maxPossibleScore > 0 else { return 0 }
        return Int((Double(totalScore) / Double(maxPossibleScore)) * 100)
    }

    var canGoBack: Bool {
        currentActivityIndex > 0
    }

    var canGoNext: Bool {
        guard let activity = currentActivity else { return false }
        return completedActivityIds.contains(activity.id)
    }

    var isLastActivity: Bool {
        currentActivityIndex == totalActivities - 1
    }

    var isCurrentActivityCompleted: Bool {
        guard let activity = currentActivity else { return false }
        return completedActivityIds.contains(activity.id)
    }

    // MARK: - Initialization

    init(lesson: Lesson, existingProgress: LessonProgress? = nil) {
        self.lesson = lesson
        self.existingProgress = existingProgress
        restoreProgress()
    }

    // MARK: - Progress Restoration

    private func restoreProgress() {
        guard let progress = existingProgress else { return }

        currentActivityIndex = min(progress.currentActivityIndex, totalActivities - 1)

        for activityProgress in progress.activityProgress {
            if activityProgress.completed {
                completedActivityIds.insert(activityProgress.activityId)
                if let score = activityProgress.score {
                    activityScores[activityProgress.activityId] = score
                }
            }
        }
    }

    // MARK: - Navigation

    func goToNext() {
        if isLastActivity && isCurrentActivityCompleted {
            completeLesson()
        } else if currentActivityIndex < totalActivities - 1 {
            currentActivityIndex += 1
        }
    }

    func goToPrevious() {
        if currentActivityIndex > 0 {
            currentActivityIndex -= 1
        }
    }

    func goToActivity(at index: Int) {
        guard index >= 0 && index < totalActivities else { return }
        currentActivityIndex = index
    }

    // MARK: - Activity Completion

    func completeCurrentActivity(score: Int?) {
        guard let activity = currentActivity else { return }

        completedActivityIds.insert(activity.id)

        if let score = score {
            activityScores[activity.id] = score
        } else if let points = activity.points {
            activityScores[activity.id] = points
        }

        // Auto-progress after short delay if not last activity
        if !isLastActivity {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                withAnimation(L2RTheme.Animation.bounce) {
                    self?.goToNext()
                }
            }
        }
    }

    // MARK: - Lesson Completion

    private func completeLesson() {
        withAnimation(L2RTheme.Animation.bounce) {
            isCompleted = true
        }
    }

    // MARK: - Progress Export

    func buildProgress(childId: String) -> LessonProgress {
        let activityProgress = sortedActivities.map { activity in
            ActivityProgress(
                activityId: activity.id,
                completed: completedActivityIds.contains(activity.id),
                score: activityScores[activity.id],
                attempts: 1,
                timeSpentSeconds: 0,
                completedAt: completedActivityIds.contains(activity.id) ? ISO8601DateFormatter().string(from: Date()) : nil
            )
        }

        return LessonProgress(
            lessonId: lesson.id,
            childId: childId,
            status: isCompleted ? .completed : .inProgress,
            currentActivityIndex: currentActivityIndex,
            activityProgress: activityProgress,
            overallScore: totalScore,
            totalTimeSeconds: 0,
            startedAt: existingProgress?.startedAt ?? ISO8601DateFormatter().string(from: Date()),
            completedAt: isCompleted ? ISO8601DateFormatter().string(from: Date()) : nil
        )
    }
}
