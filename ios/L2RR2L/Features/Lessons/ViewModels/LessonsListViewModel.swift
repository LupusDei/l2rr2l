import Foundation
import Combine

/// ViewModel for the lessons list with filtering and search capabilities.
@MainActor
final class LessonsListViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var lessons: [Lesson] = []
    @Published var searchText: String = ""
    @Published var selectedSubject: LessonSubject?
    @Published var selectedDifficulty: DifficultyLevel?
    @Published var isRefreshing: Bool = false

    // MARK: - Computed Properties

    var filteredLessons: [Lesson] {
        var result = lessons

        // Filter by search text
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            result = result.filter { lesson in
                lesson.title.lowercased().contains(lowercasedSearch) ||
                lesson.description.lowercased().contains(lowercasedSearch) ||
                lesson.objectives.contains { $0.lowercased().contains(lowercasedSearch) } ||
                (lesson.tags?.contains { $0.lowercased().contains(lowercasedSearch) } ?? false)
            }
        }

        // Filter by subject
        if let subject = selectedSubject {
            result = result.filter { $0.subject == subject }
        }

        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }

        return result
    }

    var hasActiveFilters: Bool {
        selectedSubject != nil || selectedDifficulty != nil || !searchText.isEmpty
    }

    var isEmpty: Bool {
        !isLoading && filteredLessons.isEmpty
    }

    var showEmptySearchState: Bool {
        isEmpty && hasActiveFilters && !lessons.isEmpty
    }

    var showEmptyState: Bool {
        isEmpty && !hasActiveFilters
    }

    // MARK: - Initialization

    override init() {
        super.init()
        setupSearchDebounce()
    }

    // MARK: - Lifecycle

    override func refresh() async {
        await fetchLessons()
    }

    // MARK: - Data Fetching

    func fetchLessons() async {
        await performAsyncAction {
            let endpoint = LessonsEndpoints.list(
                subject: self.selectedSubject?.rawValue,
                difficulty: self.selectedDifficulty?.rawValue,
                limit: 50,
                offset: 0
            )

            let response: LessonListResponse = try await APIClient.shared.get(endpoint.path)
            self.lessons = response.lessons
        }
    }

    func refreshLessons() async {
        isRefreshing = true
        await fetchLessons()
        isRefreshing = false
    }

    // MARK: - Filter Actions

    func clearFilters() {
        searchText = ""
        selectedSubject = nil
        selectedDifficulty = nil
    }

    func setSubject(_ subject: LessonSubject?) {
        selectedSubject = subject
    }

    func setDifficulty(_ difficulty: DifficultyLevel?) {
        selectedDifficulty = difficulty
    }

    // MARK: - Private Methods

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                // Search is handled locally via filteredLessons computed property
                // This debounce prevents excessive UI updates during typing
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
