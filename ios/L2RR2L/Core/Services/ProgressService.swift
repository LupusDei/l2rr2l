import Foundation

@MainActor
final class ProgressService: ObservableObject {
    static let shared = ProgressService()

    @Published private(set) var progressByLesson: [String: LessonProgress] = [:]
    @Published private(set) var stats: LearningStats?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let apiClient: APIClient
    private let cacheKey = "cached_progress"
    private let pendingUpdatesKey = "pending_progress_updates"

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        loadCachedProgress()
    }

    // MARK: - Public Methods

    func startLesson(childId: String, lessonId: String) async throws -> LessonProgress {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response: ProgressResponse = try await apiClient.request(
                ProgressEndpoints.startLesson(childId: childId, lessonId: lessonId)
            )
            let progress = response.progress
            updateCache(progress)
            return progress
        } catch {
            // Queue for offline sync if network error
            if isNetworkError(error) {
                let pendingProgress = createPendingProgress(childId: childId, lessonId: lessonId, status: .inProgress)
                queuePendingUpdate(.start(childId: childId, lessonId: lessonId))
                updateCache(pendingProgress)
                return pendingProgress
            }
            self.error = error
            throw error
        }
    }

    func updateProgress(childId: String, lessonId: String, status: LessonStatus? = nil, score: Int? = nil, timeSpent: Int? = nil) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response: ProgressResponse = try await apiClient.request(
                ProgressEndpoints.update(
                    childId: childId,
                    lessonId: lessonId,
                    status: status?.rawValue,
                    score: score,
                    timeSpent: timeSpent
                )
            )
            updateCache(response.progress)
        } catch {
            if isNetworkError(error) {
                queuePendingUpdate(.update(childId: childId, lessonId: lessonId, status: status, score: score, timeSpent: timeSpent))
                // Update local cache optimistically
                if var existing = progressByLesson["\(lessonId)-\(childId)"] {
                    // Create updated progress locally
                    let updated = LessonProgress(
                        lessonId: existing.lessonId,
                        childId: existing.childId,
                        status: status ?? existing.status,
                        currentActivityIndex: existing.currentActivityIndex,
                        activityProgress: existing.activityProgress,
                        overallScore: score ?? existing.overallScore,
                        totalTimeSeconds: timeSpent ?? existing.totalTimeSeconds,
                        startedAt: existing.startedAt,
                        completedAt: existing.completedAt
                    )
                    updateCache(updated)
                }
                return
            }
            self.error = error
            throw error
        }
    }

    func completeLesson(childId: String, lessonId: String, score: Int? = nil, timeSpent: Int? = nil) async throws -> LessonProgress {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response: ProgressResponse = try await apiClient.request(
                ProgressEndpoints.completeLesson(childId: childId, lessonId: lessonId, score: score, timeSpent: timeSpent)
            )
            updateCache(response.progress)
            return response.progress
        } catch {
            if isNetworkError(error) {
                queuePendingUpdate(.complete(childId: childId, lessonId: lessonId, score: score, timeSpent: timeSpent))
                // Optimistically update local cache
                let completedProgress = createCompletedProgress(childId: childId, lessonId: lessonId, score: score, timeSpent: timeSpent)
                updateCache(completedProgress)
                return completedProgress
            }
            self.error = error
            throw error
        }
    }

    func getProgress(childId: String, lessonId: String) async throws -> LessonProgress? {
        // Check cache first
        let cacheKey = "\(lessonId)-\(childId)"
        if let cached = progressByLesson[cacheKey] {
            return cached
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response: ProgressResponse = try await apiClient.request(
                ProgressEndpoints.forLesson(childId: childId, lessonId: lessonId)
            )
            updateCache(response.progress)
            return response.progress
        } catch let apiError as APIError {
            if case .notFound = apiError {
                return nil
            }
            self.error = apiError
            throw apiError
        } catch {
            self.error = error
            throw error
        }
    }

    func getSummary(childId: String) async throws -> LearningStats {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: StatsResponse = try await apiClient.request(
            ProgressEndpoints.stats(childId: childId)
        )
        self.stats = response.stats
        return response.stats
    }

    func fetchAllProgress(childId: String) async throws -> [LessonProgress] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: ProgressListResponse = try await apiClient.request(
            ProgressEndpoints.forChild(childId: childId)
        )

        // Update cache with all progress
        for progress in response.progress {
            updateCache(progress)
        }

        return response.progress
    }

    func saveActivityProgress(
        childId: String,
        lessonId: String,
        activityId: String,
        completed: Bool,
        score: Int? = nil,
        attempts: Int? = nil,
        timeSpentSeconds: Int? = nil,
        currentActivityIndex: Int? = nil
    ) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response: ProgressResponse = try await apiClient.request(
                ProgressEndpoints.saveActivity(
                    childId: childId,
                    lessonId: lessonId,
                    activityId: activityId,
                    completed: completed,
                    score: score,
                    attempts: attempts,
                    timeSpentSeconds: timeSpentSeconds,
                    currentActivityIndex: currentActivityIndex
                )
            )
            updateCache(response.progress)
        } catch {
            if isNetworkError(error) {
                queuePendingUpdate(.activity(
                    childId: childId,
                    lessonId: lessonId,
                    activityId: activityId,
                    completed: completed,
                    score: score,
                    attempts: attempts,
                    timeSpentSeconds: timeSpentSeconds,
                    currentActivityIndex: currentActivityIndex
                ))
                return
            }
            self.error = error
            throw error
        }
    }

    func syncPendingUpdates() async {
        let pendingUpdates = loadPendingUpdates()
        guard !pendingUpdates.isEmpty else { return }

        var remainingUpdates: [PendingUpdate] = []

        for update in pendingUpdates {
            do {
                switch update {
                case .start(let childId, let lessonId):
                    _ = try await apiClient.request(
                        ProgressEndpoints.startLesson(childId: childId, lessonId: lessonId)
                    ) as ProgressResponse

                case .update(let childId, let lessonId, let status, let score, let timeSpent):
                    _ = try await apiClient.request(
                        ProgressEndpoints.update(
                            childId: childId,
                            lessonId: lessonId,
                            status: status?.rawValue,
                            score: score,
                            timeSpent: timeSpent
                        )
                    ) as ProgressResponse

                case .complete(let childId, let lessonId, let score, let timeSpent):
                    _ = try await apiClient.request(
                        ProgressEndpoints.completeLesson(childId: childId, lessonId: lessonId, score: score, timeSpent: timeSpent)
                    ) as ProgressResponse

                case .activity(let childId, let lessonId, let activityId, let completed, let score, let attempts, let timeSpentSeconds, let currentActivityIndex):
                    _ = try await apiClient.request(
                        ProgressEndpoints.saveActivity(
                            childId: childId,
                            lessonId: lessonId,
                            activityId: activityId,
                            completed: completed,
                            score: score,
                            attempts: attempts,
                            timeSpentSeconds: timeSpentSeconds,
                            currentActivityIndex: currentActivityIndex
                        )
                    ) as ProgressResponse
                }
            } catch {
                if isNetworkError(error) {
                    remainingUpdates.append(update)
                }
                // Non-network errors are dropped (e.g., conflict, not found)
            }
        }

        savePendingUpdates(remainingUpdates)
    }

    func clearCache() {
        progressByLesson.removeAll()
        stats = nil
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    // MARK: - Private Methods

    private func updateCache(_ progress: LessonProgress) {
        progressByLesson[progress.id] = progress
        persistCache()
    }

    private func loadCachedProgress() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode([String: LessonProgress].self, from: data) else {
            return
        }
        progressByLesson = cached
    }

    private func persistCache() {
        guard let data = try? JSONEncoder().encode(progressByLesson) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func createPendingProgress(childId: String, lessonId: String, status: LessonStatus) -> LessonProgress {
        let now = ISO8601DateFormatter().string(from: Date())
        return LessonProgress(
            lessonId: lessonId,
            childId: childId,
            status: status,
            currentActivityIndex: 0,
            activityProgress: [],
            overallScore: nil,
            totalTimeSeconds: 0,
            startedAt: now,
            completedAt: nil
        )
    }

    private func createCompletedProgress(childId: String, lessonId: String, score: Int?, timeSpent: Int?) -> LessonProgress {
        let now = ISO8601DateFormatter().string(from: Date())
        let existing = progressByLesson["\(lessonId)-\(childId)"]
        return LessonProgress(
            lessonId: lessonId,
            childId: childId,
            status: .completed,
            currentActivityIndex: existing?.currentActivityIndex ?? 0,
            activityProgress: existing?.activityProgress ?? [],
            overallScore: score,
            totalTimeSeconds: timeSpent ?? existing?.totalTimeSeconds ?? 0,
            startedAt: existing?.startedAt ?? now,
            completedAt: now
        )
    }

    private func isNetworkError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError, .serviceUnavailable:
                return true
            default:
                return false
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return true
            default:
                return false
            }
        }
        return false
    }

    private func queuePendingUpdate(_ update: PendingUpdate) {
        var updates = loadPendingUpdates()
        updates.append(update)
        savePendingUpdates(updates)
    }

    private func loadPendingUpdates() -> [PendingUpdate] {
        guard let data = UserDefaults.standard.data(forKey: pendingUpdatesKey),
              let updates = try? JSONDecoder().decode([PendingUpdate].self, from: data) else {
            return []
        }
        return updates
    }

    private func savePendingUpdates(_ updates: [PendingUpdate]) {
        guard let data = try? JSONEncoder().encode(updates) else { return }
        UserDefaults.standard.set(data, forKey: pendingUpdatesKey)
    }
}

// MARK: - Response Types

private struct ProgressResponse: Decodable {
    let progress: LessonProgress
}

private struct ProgressListResponse: Decodable {
    let progress: [LessonProgress]
}

private struct StatsResponse: Decodable {
    let stats: LearningStats
}

// MARK: - Pending Update Types

private enum PendingUpdate: Codable {
    case start(childId: String, lessonId: String)
    case update(childId: String, lessonId: String, status: LessonStatus?, score: Int?, timeSpent: Int?)
    case complete(childId: String, lessonId: String, score: Int?, timeSpent: Int?)
    case activity(childId: String, lessonId: String, activityId: String, completed: Bool, score: Int?, attempts: Int?, timeSpentSeconds: Int?, currentActivityIndex: Int?)
}
