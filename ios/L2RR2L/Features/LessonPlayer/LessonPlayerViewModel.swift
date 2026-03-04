import Foundation

/// ViewModel for the Lesson Player.
/// Manages lesson loading, activity progression, and progress tracking.
@MainActor
class LessonPlayerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var lesson: Lesson?
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentActivityIndex = 0
    @Published private(set) var playerState: LessonPlayerState = .loading
    @Published private(set) var activityResults: [ActivityResult] = []

    // MARK: - Properties

    let lessonId: String
    private let apiClient = APIClient.shared
    private let startTime = Date()

    // MARK: - Computed Properties

    var activities: [LessonActivity] {
        lesson?.activities ?? []
    }

    var currentActivity: LessonActivity? {
        guard currentActivityIndex >= 0 && currentActivityIndex < activities.count else {
            return nil
        }
        return activities[currentActivityIndex]
    }

    var totalActivities: Int {
        activities.count
    }

    var isFirstActivity: Bool {
        currentActivityIndex == 0
    }

    var isLastActivity: Bool {
        currentActivityIndex == activities.count - 1
    }

    var progress: Double {
        guard totalActivities > 0 else { return 0 }
        return Double(currentActivityIndex) / Double(totalActivities)
    }

    var completionProgress: Double {
        guard totalActivities > 0 else { return 0 }
        return Double(activityResults.count) / Double(totalActivities)
    }

    var overallScore: Int {
        let completed = activityResults.filter { $0.completed }
        guard !completed.isEmpty else { return 0 }
        let total = completed.reduce(0) { $0 + $1.score }
        return total / completed.count
    }

    var objectives: [LessonObjective] {
        lesson?.objectives ?? []
    }

    var durationMinutes: Int {
        lesson?.durationMinutes ?? 15
    }

    // MARK: - Initialization

    init(lessonId: String) {
        self.lessonId = lessonId
    }

    // MARK: - Public Methods

    func loadLesson() async {
        isLoading = true
        errorMessage = nil
        playerState = .loading

        // Try cache first
        if let cached = await LessonCacheService.shared.getCachedLesson(id: lessonId) {
            lesson = cached
            isLoading = false
            playerState = .objectives
            return
        }

        // Fetch from API
        do {
            let endpoint = LessonsEndpoints.get(id: lessonId)
            let response: LessonResponse = try await apiClient.request(endpoint)
            lesson = response.lesson
            isLoading = false
            playerState = activities.isEmpty ? .complete : .objectives
        } catch {
            errorMessage = "Could not load lesson."
            isLoading = false
            playerState = .error
        }
    }

    func startLesson() {
        guard !activities.isEmpty else {
            playerState = .complete
            return
        }
        currentActivityIndex = 0
        activityResults = []
        playerState = .activity
    }

    func completeCurrentActivity(score: Int = 100) {
        guard let activity = currentActivity else { return }

        let result = ActivityResult(
            activityId: activity.id ?? UUID().uuidString,
            completed: true,
            score: score,
            timeSpentSeconds: Int(Date().timeIntervalSince(startTime))
        )
        activityResults.append(result)

        if isLastActivity {
            playerState = .complete
        } else {
            currentActivityIndex += 1
        }
    }

    func skipCurrentActivity() {
        guard let activity = currentActivity else { return }

        let result = ActivityResult(
            activityId: activity.id ?? UUID().uuidString,
            completed: false,
            score: 0,
            timeSpentSeconds: 0
        )
        activityResults.append(result)

        if isLastActivity {
            playerState = .complete
        } else {
            currentActivityIndex += 1
        }
    }

    func goToPreviousActivity() {
        guard currentActivityIndex > 0 else { return }
        currentActivityIndex -= 1
    }

    func goToNextActivity() {
        guard currentActivityIndex < activities.count - 1 else { return }
        currentActivityIndex += 1
    }
}

// MARK: - Supporting Types

enum LessonPlayerState {
    case loading
    case objectives
    case activity
    case complete
    case error
}

struct ActivityResult {
    let activityId: String
    let completed: Bool
    let score: Int
    let timeSpentSeconds: Int
}
