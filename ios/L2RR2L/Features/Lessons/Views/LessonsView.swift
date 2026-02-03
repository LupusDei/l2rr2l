import SwiftUI

struct LessonsView: View {
    @StateObject private var viewModel = LessonsListViewModel()
    @ObservedObject var router = NavigationRouter.shared

    var body: some View {
        VStack(spacing: 0) {
            searchAndFilterSection

            contentSection
        }
        .background(L2RTheme.background)
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Lessons.listView)
    }

    // MARK: - Search & Filter Section

    private var searchAndFilterSection: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            searchBar

            filterChips
        }
        .padding(.horizontal, L2RTheme.Spacing.lg)
        .padding(.vertical, L2RTheme.Spacing.sm)
        .background(Color.white)
    }

    private var searchBar: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)

            TextField("Search lessons...", text: $viewModel.searchText)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("lessons.search.textfield")

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(L2RTheme.textSecondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(L2RTheme.Spacing.sm)
        .background(L2RTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: L2RTheme.Spacing.xs) {
                subjectFilterMenu
                difficultyFilterMenu

                if viewModel.hasActiveFilters {
                    clearFiltersButton
                }
            }
        }
    }

    private var subjectFilterMenu: some View {
        Menu {
            Button("All Subjects") {
                viewModel.setSubject(nil)
            }

            ForEach(LessonSubject.allCases, id: \.self) { subject in
                Button {
                    viewModel.setSubject(subject)
                } label: {
                    HStack {
                        Text(subjectDisplayName(subject))
                        if viewModel.selectedSubject == subject {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            filterChip(
                title: viewModel.selectedSubject.map { subjectDisplayName($0) } ?? "Subject",
                isActive: viewModel.selectedSubject != nil
            )
        }
        .accessibilityIdentifier("lessons.filter.subject")
    }

    private var difficultyFilterMenu: some View {
        Menu {
            Button("All Levels") {
                viewModel.setDifficulty(nil)
            }

            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                Button {
                    viewModel.setDifficulty(level)
                } label: {
                    HStack {
                        Text(difficultyDisplayName(level))
                        if viewModel.selectedDifficulty == level {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            filterChip(
                title: viewModel.selectedDifficulty.map { difficultyDisplayName($0) } ?? "Difficulty",
                isActive: viewModel.selectedDifficulty != nil
            )
        }
        .accessibilityIdentifier("lessons.filter.difficulty")
    }

    private var clearFiltersButton: some View {
        Button {
            viewModel.clearFilters()
        } label: {
            HStack(spacing: L2RTheme.Spacing.xxs) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                Text("Clear")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
            }
            .foregroundStyle(L2RTheme.Status.error)
            .padding(.horizontal, L2RTheme.Spacing.sm)
            .padding(.vertical, L2RTheme.Spacing.xs)
            .background(L2RTheme.Status.error.opacity(0.1))
            .clipShape(Capsule())
        }
        .accessibilityLabel("Clear all filters")
    }

    private func filterChip(title: String, isActive: Bool) -> some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Text(title)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))

            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(isActive ? .white : L2RTheme.textPrimary)
        .padding(.horizontal, L2RTheme.Spacing.sm)
        .padding(.vertical, L2RTheme.Spacing.xs)
        .background(isActive ? L2RTheme.primary : L2RTheme.background)
        .clipShape(Capsule())
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading && viewModel.lessons.isEmpty {
            loadingState
        } else if let error = viewModel.errorMessage {
            errorState(error)
        } else if viewModel.showEmptyState {
            emptyState
        } else if viewModel.showEmptySearchState {
            emptySearchState
        } else {
            lessonsList
        }
    }

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: L2RTheme.Spacing.md) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonListItem()
                }
            }
            .padding(L2RTheme.Spacing.lg)
        }
    }

    private func errorState(_ error: String) -> some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(L2RTheme.Status.error)

            VStack(spacing: L2RTheme.Spacing.xs) {
                Text("Something went wrong")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)

                Text(error)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await viewModel.fetchLessons()
                }
            } label: {
                Text("Try Again")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(L2RTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }

            Spacer()
        }
        .padding(L2RTheme.Spacing.lg)
        .accessibilityIdentifier("lessons.error.view")
    }

    private var emptyState: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(L2RTheme.textMuted)

            VStack(spacing: L2RTheme.Spacing.xs) {
                Text("No Lessons Available")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)

                Text("Check back later for new lessons!")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            Spacer()
        }
        .padding(L2RTheme.Spacing.lg)
        .accessibilityIdentifier("lessons.empty.state")
    }

    private var emptySearchState: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(L2RTheme.textMuted)

            VStack(spacing: L2RTheme.Spacing.xs) {
                Text("No Lessons Found")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)

                Text("Try adjusting your filters or search terms")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            Button {
                viewModel.clearFilters()
            } label: {
                Text("Clear Filters")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(L2RTheme.primary)
            }

            Spacer()
        }
        .padding(L2RTheme.Spacing.lg)
        .accessibilityIdentifier("lessons.empty.search")
    }

    private var lessonsList: some View {
        ScrollView {
            LazyVStack(spacing: L2RTheme.Spacing.md) {
                headerSection

                ForEach(Array(viewModel.filteredLessons.enumerated()), id: \.element.id) { index, lesson in
                    LessonCard(lesson: lesson) {
                        router.lessonsPath.append(LessonDestination.detail(id: lesson.id))
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Lessons.lessonCard(index: index))
                }
            }
            .padding(L2RTheme.Spacing.lg)
        }
        .refreshable {
            await viewModel.refreshLessons()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            Text("Your Learning Journey")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            Text(headerSubtitle)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier(AccessibilityIdentifiers.Lessons.headerSection)
    }

    private var headerSubtitle: String {
        let count = viewModel.filteredLessons.count
        if viewModel.hasActiveFilters {
            return "\(count) lesson\(count == 1 ? "" : "s") found"
        } else {
            return "Keep going! You're doing great!"
        }
    }

    // MARK: - Helper Methods

    private func subjectDisplayName(_ subject: LessonSubject) -> String {
        switch subject {
        case .phonics: return "Phonics"
        case .spelling: return "Spelling"
        case .sightWords: return "Sight Words"
        case .reading: return "Reading"
        case .wordFamilies: return "Word Families"
        case .vocabulary: return "Vocabulary"
        case .comprehension: return "Comprehension"
        }
    }

    private func difficultyDisplayName(_ level: DifficultyLevel) -> String {
        switch level {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

#Preview {
    NavigationStack {
        LessonsView()
    }
}
