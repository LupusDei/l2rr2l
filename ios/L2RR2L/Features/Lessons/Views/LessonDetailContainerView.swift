import SwiftUI

/// Container view that loads a lesson by ID and displays the detail view.
/// Handles loading states and navigation to the lesson player.
struct LessonDetailContainerView: View {
    let lessonId: String

    @ObservedObject var router = NavigationRouter.shared
    @State private var lesson: Lesson?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let lesson = lesson {
                LessonDetailView(
                    lesson: lesson,
                    onStart: {
                        startLesson()
                    }
                )
            } else {
                errorView
            }
        }
        .task {
            await loadLesson()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(L2RTheme.primary)

            Text("Loading lesson...")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(L2RTheme.background)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(L2RTheme.Status.warning)

            Text("Lesson Not Found")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title2, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                router.popToRoot(tab: .lessons)
            } label: {
                Text("Back to Lessons")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(L2RTheme.primary)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(L2RTheme.background)
    }

    // MARK: - Data Loading

    private func loadLesson() async {
        isLoading = true
        errorMessage = nil

        // Try to load from cache
        if let cachedLesson = await LessonCacheService.shared.getCachedLesson(id: lessonId) {
            lesson = cachedLesson
            isLoading = false
            return
        }

        // Try to fetch from API
        do {
            let endpoint = LessonsEndpoints.get(id: lessonId)
            let response: LessonResponse = try await APIClient.shared.request(endpoint)
            lesson = response.lesson
            isLoading = false
        } catch {
            errorMessage = "Could not find lesson with ID: \(lessonId)"
            isLoading = false
        }
    }

    // MARK: - Actions

    private func startLesson() {
        // Navigate to lesson player
        router.lessonsPath.append(LessonDestination.player(id: lessonId))
    }
}

#Preview("Loading") {
    NavigationStack {
        LessonDetailContainerView(lessonId: "loading-test")
    }
}

#Preview("Not Found") {
    NavigationStack {
        LessonDetailContainerView(lessonId: "nonexistent-lesson")
    }
}
