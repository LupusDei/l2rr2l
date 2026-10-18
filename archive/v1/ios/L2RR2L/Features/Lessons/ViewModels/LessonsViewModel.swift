import Foundation
import Combine

/// ViewModel for lesson browsing, filtering, and search.
@MainActor
final class LessonsViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true

    @Published var selectedSubject: String?
    @Published var selectedDifficulty: String?
    @Published var searchQuery = ""

    // MARK: - Private Properties

    private let apiClient: APIClient
    private let cacheService: LessonCacheService
    private let pageSize = 20
    private var currentOffset = 0
    private var searchDebounceTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        apiClient: APIClient = .shared,
        cacheService: LessonCacheService = .shared
    ) {
        self.apiClient = apiClient
        self.cacheService = cacheService
        super.init()
        setupSearchDebounce()
    }

    // MARK: - Lifecycle

    override func onAppear() {
        if lessons.isEmpty {
            Task {
                await fetchLessons()
            }
        }
    }

    override func refresh() async {
        await refreshLessons()
    }

    // MARK: - Public Methods

    /// Fetches the initial set of lessons.
    func fetchLessons() async {
        // Try cache first
        if let cached = await cacheService.getCachedLessons(), !cached.isEmpty, !hasActiveFilters {
            lessons = cached
            return
        }

        currentOffset = 0
        hasMorePages = true

        await performAsyncAction { [weak self] in
            guard let self else { return }
            let response = try await self.fetchLessonsFromAPI(offset: 0)
            self.lessons = response.lessons
            self.hasMorePages = response.lessons.count >= self.pageSize
            self.currentOffset = response.lessons.count

            // Cache if no filters active
            if !self.hasActiveFilters {
                await self.cacheService.cacheLessons(response.lessons)
            }
        }
    }

    /// Loads the next page of lessons.
    func loadMore() async {
        guard !isLoading, !isLoadingMore, hasMorePages else { return }

        isLoadingMore = true

        do {
            let response = try await fetchLessonsFromAPI(offset: currentOffset)
            lessons.append(contentsOf: response.lessons)
            currentOffset += response.lessons.count
            hasMorePages = response.lessons.count >= pageSize
        } catch {
            handleError(error)
        }

        isLoadingMore = false
    }

    /// Refreshes the lessons list (pull-to-refresh).
    func refreshLessons() async {
        // Invalidate cache on manual refresh
        await cacheService.invalidateAll()

        currentOffset = 0
        hasMorePages = true

        await performAsyncAction { [weak self] in
            guard let self else { return }
            let response = try await self.fetchLessonsFromAPI(offset: 0)
            self.lessons = response.lessons
            self.hasMorePages = response.lessons.count >= self.pageSize
            self.currentOffset = response.lessons.count

            // Re-cache fresh data if no filters
            if !self.hasActiveFilters {
                await self.cacheService.cacheLessons(response.lessons)
            }
        }
    }

    /// Applies current filters and refetches lessons.
    func applyFilters() {
        Task {
            await fetchLessons()
        }
    }

    /// Clears all filters and refetches lessons.
    func clearFilters() {
        selectedSubject = nil
        selectedDifficulty = nil
        searchQuery = ""
        applyFilters()
    }

    /// Performs a search with the given query.
    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await fetchLessons()
            return
        }

        currentOffset = 0
        hasMorePages = true

        await performAsyncAction { [weak self] in
            guard let self else { return }
            let response: LessonsResponse = try await self.apiClient.request(
                LessonsEndpoints.search(query: query, limit: self.pageSize, offset: 0)
            )
            self.lessons = response.lessons
            self.hasMorePages = response.lessons.count >= self.pageSize
            self.currentOffset = response.lessons.count
        }
    }

    // MARK: - Computed Properties

    /// Whether any filters are currently active.
    var hasActiveFilters: Bool {
        selectedSubject != nil ||
        selectedDifficulty != nil ||
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns subjects for filter UI.
    var availableSubjects: [LessonSubject] {
        LessonSubject.allCases
    }

    /// Returns difficulty levels for filter UI.
    var availableDifficulties: [DifficultyLevel] {
        DifficultyLevel.allCases
    }

    // MARK: - Private Methods

    private func fetchLessonsFromAPI(offset: Int) async throws -> LessonsResponse {
        let endpoint = LessonsEndpoints.list(
            subject: selectedSubject,
            difficulty: selectedDifficulty,
            limit: pageSize,
            offset: offset
        )
        return try await apiClient.request(endpoint)
    }

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchDebounceTask?.cancel()
                self?.searchDebounceTask = Task {
                    await self?.search(query: query)
                }
            }
            .store(in: &cancellables)
    }
}
