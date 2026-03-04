import SwiftUI

/// Full lesson player that replaces the placeholder.
/// Fetches lesson by ID, shows objectives, progresses through activities, and shows completion.
struct LessonPlayerView: View {
    let lessonId: String

    @StateObject private var viewModel: LessonPlayerViewModel
    @Environment(\.dismiss) private var dismiss

    private let voiceService = VoiceService.shared

    init(lessonId: String) {
        self.lessonId = lessonId
        self._viewModel = StateObject(wrappedValue: LessonPlayerViewModel(lessonId: lessonId))
    }

    var body: some View {
        Group {
            switch viewModel.playerState {
            case .loading:
                loadingView
            case .objectives:
                objectivesView
            case .activity:
                activityView
            case .complete:
                completionView
            case .error:
                errorView
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadLesson()
        }
        .onChange(of: viewModel.playerState) { _, newState in
            switch newState {
            case .objectives:
                if let title = viewModel.lesson?.title {
                    Task { await voiceService.speak(title) }
                }
            case .complete:
                Task { await voiceService.speak("Great job! You finished the lesson!") }
            default:
                break
            }
        }
        .onChange(of: viewModel.currentActivityIndex) { _, _ in
            if let activity = viewModel.currentActivity, let title = activity.title {
                Task { await voiceService.speak(title) }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            LoadingSpinner(size: .large, color: L2RTheme.primary)

            Text("Loading lesson...")
                .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(L2RTheme.background)
    }

    // MARK: - Objectives View

    private var objectivesView: some View {
        ScrollView {
            VStack(spacing: L2RTheme.Spacing.xl) {
                Spacer(minLength: L2RTheme.Spacing.xxl)

                // Lesson icon
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(L2RTheme.primary)

                // Title
                if let lesson = viewModel.lesson {
                    Text(lesson.title)
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title, weight: .bold))
                        .foregroundStyle(L2RTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Description
                    if let description = lesson.description {
                        Text(description)
                            .font(L2RTheme.Typography.Scaled.system(.callout))
                            .foregroundStyle(L2RTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, L2RTheme.Spacing.xl)
                    }
                }

                // Objectives
                if !viewModel.objectives.isEmpty {
                    VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
                        Text("What you'll learn:")
                            .font(L2RTheme.Typography.Scaled.system(.body, weight: .semibold))
                            .foregroundStyle(L2RTheme.textPrimary)

                        ForEach(viewModel.objectives.indices, id: \.self) { index in
                            let objective = viewModel.objectives[index]
                            HStack(alignment: .top, spacing: L2RTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(L2RTheme.Status.success)

                                Text(objective.text ?? objective.description ?? "")
                                    .font(L2RTheme.Typography.Scaled.system(.callout))
                                    .foregroundStyle(L2RTheme.textPrimary)
                            }
                        }
                    }
                    .padding(L2RTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(L2RTheme.Status.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                    .padding(.horizontal, L2RTheme.Spacing.lg)
                }

                // Meta info
                HStack(spacing: L2RTheme.Spacing.xl) {
                    Label("\(viewModel.totalActivities) activities", systemImage: "list.bullet")
                    Label("~\(viewModel.durationMinutes) min", systemImage: "clock")
                }
                .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)

                // Buttons
                VStack(spacing: L2RTheme.Spacing.md) {
                    Button {
                        viewModel.startLesson()
                    } label: {
                        HStack(spacing: L2RTheme.Spacing.sm) {
                            Image(systemName: "play.fill")
                            Text("Start Lesson")
                                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: L2RTheme.TouchTarget.xlarge)
                        .background(LinearGradient.ctaButton)
                        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
                        .shadow(color: L2RTheme.CTA.shadow.opacity(0.4), radius: 6, y: 4)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Back")
                            .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                            .foregroundStyle(L2RTheme.textSecondary)
                    }
                }
                .padding(.horizontal, L2RTheme.Spacing.xl)
                .padding(.top, L2RTheme.Spacing.lg)

                Spacer(minLength: L2RTheme.Spacing.xxl)
            }
        }
        .background(L2RTheme.background)
    }

    // MARK: - Activity View

    private var activityView: some View {
        VStack(spacing: 0) {
            // Progress header
            activityHeader

            // Activity content
            ScrollView {
                VStack(spacing: L2RTheme.Spacing.xl) {
                    if let activity = viewModel.currentActivity {
                        activityContent(activity)
                    }
                }
                .padding(L2RTheme.Spacing.lg)
            }

            // Navigation controls
            activityNavigation
        }
        .background(L2RTheme.background)
    }

    private var activityHeader: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            HStack {
                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(L2RTheme.textSecondary.opacity(0.6))
                        .frame(minWidth: L2RTheme.TouchTarget.minimum, minHeight: L2RTheme.TouchTarget.minimum)
                }
                .accessibilityLabel("Exit lesson")

                Spacer()

                // Progress label
                Text("Activity \(viewModel.currentActivityIndex + 1) of \(viewModel.totalActivities)")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)

                Spacer()

                // Spacer for symmetry
                Color.clear.frame(width: 28, height: 28)
            }
            .padding(.horizontal, L2RTheme.Spacing.md)

            // Progress bar
            ProgressBar(
                progress: viewModel.progress,
                color: L2RTheme.primary,
                height: 6
            )
            .padding(.horizontal, L2RTheme.Spacing.md)
        }
        .padding(.vertical, L2RTheme.Spacing.sm)
        .background(Color.white)
    }

    private func activityContent(_ activity: LessonActivity) -> some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.lg) {
            // Activity type badge
            if let type = activity.type {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Image(systemName: activityIconName(for: type))
                        .font(.system(size: 14))
                    Text(activityDisplayName(for: type))
                        .font(L2RTheme.Typography.Scaled.system(.footnote, weight: .semibold))
                }
                .foregroundStyle(L2RTheme.primary)
                .padding(.horizontal, L2RTheme.Spacing.sm)
                .padding(.vertical, L2RTheme.Spacing.xxs)
                .background(L2RTheme.primary.opacity(0.1))
                .clipShape(Capsule())
            }

            // Activity title
            if let title = activity.title {
                Text(title)
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                    .foregroundStyle(L2RTheme.textPrimary)
            }

            // Activity description / instructions
            if let description = activity.description {
                Text(description)
                    .font(L2RTheme.Typography.Scaled.system(.callout))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .lineSpacing(4)
            }

            // Activity content
            if let content = activity.content {
                activityContentCard(content, type: activity.type)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activityContentCard(_ content: ActivityContent, type: String?) -> some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.md) {
            // Reading text
            if let text = content.text {
                Text(text)
                    .font(L2RTheme.Typography.Scaled.system(.body))
                    .foregroundStyle(L2RTheme.textPrimary)
                    .lineSpacing(6)
                    .padding(L2RTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            }

            // Word list
            if let words = content.words, !words.isEmpty {
                VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
                    Text("Words to practice:")
                        .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                        .foregroundStyle(L2RTheme.textPrimary)

                    WordsFlowView(words: words)
                }
            }

            // Questions
            if let questions = content.questions, !questions.isEmpty {
                VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
                    Text("Questions:")
                        .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                        .foregroundStyle(L2RTheme.textPrimary)

                    ForEach(questions.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: L2RTheme.Spacing.sm) {
                            Text("\(index + 1).")
                                .font(L2RTheme.Typography.Scaled.system(.callout, weight: .bold))
                                .foregroundStyle(L2RTheme.primary)

                            Text(questions[index])
                                .font(L2RTheme.Typography.Scaled.system(.callout))
                                .foregroundStyle(L2RTheme.textPrimary)
                        }
                    }
                }
                .padding(L2RTheme.Spacing.md)
                .background(L2RTheme.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }
        }
    }

    private var activityNavigation: some View {
        HStack(spacing: L2RTheme.Spacing.md) {
            // Back button
            Button {
                viewModel.goToPreviousActivity()
            } label: {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                .foregroundStyle(viewModel.isFirstActivity ? L2RTheme.textSecondary.opacity(0.4) : L2RTheme.primary)
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.vertical, L2RTheme.Spacing.sm)
            }
            .disabled(viewModel.isFirstActivity)

            Spacer()

            // Skip button
            Button {
                viewModel.skipCurrentActivity()
            } label: {
                Text("Skip")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .padding(.horizontal, L2RTheme.Spacing.lg)
                    .padding(.vertical, L2RTheme.Spacing.sm)
            }

            // Done / Next button
            Button {
                viewModel.completeCurrentActivity()
            } label: {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Text(viewModel.isLastActivity ? "Finish" : "Next")
                    Image(systemName: viewModel.isLastActivity ? "checkmark" : "chevron.right")
                }
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .callout, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, L2RTheme.Spacing.xl)
                .padding(.vertical, L2RTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(LinearGradient.ctaButton)
                        .shadow(color: L2RTheme.CTA.shadow.opacity(0.4), radius: 4, y: 3)
                )
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.md)
        .background(Color.white.shadow(color: Color.black.opacity(0.05), radius: 4, y: -2))
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Spacer()

            Text("\u{1F389}")
                .font(.system(size: 80))

            Text("Great Job!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            if let lesson = viewModel.lesson {
                Text("You finished \"\(lesson.title)\"!")
                    .font(L2RTheme.Typography.Scaled.system(.body))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Score
            if viewModel.overallScore > 0 {
                VStack(spacing: L2RTheme.Spacing.sm) {
                    Text("Score")
                        .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                        .foregroundStyle(L2RTheme.textSecondary)

                    Text("\(viewModel.overallScore)%")
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                        .foregroundStyle(L2RTheme.primary)
                }
                .padding(L2RTheme.Spacing.lg)
                .background(L2RTheme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }

            // Activities completed
            let completed = viewModel.activityResults.filter { $0.completed }.count
            Text("\(completed) of \(viewModel.totalActivities) activities completed")
                .font(L2RTheme.Typography.Scaled.system(.callout))
                .foregroundStyle(L2RTheme.textSecondary)

            Spacer()

            // Done button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: L2RTheme.TouchTarget.xlarge)
                    .background(LinearGradient.ctaButton)
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
                    .shadow(color: L2RTheme.CTA.shadow.opacity(0.4), radius: 6, y: 4)
            }
            .padding(.horizontal, L2RTheme.Spacing.xl)
            .padding(.bottom, L2RTheme.Spacing.xxl)
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

            Text("Could Not Load Lesson")
                .font(L2RTheme.Typography.Scaled.system(.title2, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(L2RTheme.Typography.Scaled.system(.callout))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.loadLesson() }
            } label: {
                Text("Try Again")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                    .foregroundStyle(L2RTheme.primary)
            }

            Button {
                dismiss()
            } label: {
                Text("Go Back")
                    .font(L2RTheme.Typography.Scaled.system(.callout))
                    .foregroundStyle(L2RTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(L2RTheme.background)
    }

    // MARK: - Helpers

    private func activityDisplayName(for type: String) -> String {
        switch type.lowercased() {
        case "reading": return "Reading"
        case "spelling": return "Spelling"
        case "phonics": return "Phonics"
        case "sight-words": return "Sight Words"
        case "quiz": return "Quiz"
        case "matching": return "Matching"
        case "fill-in-blank": return "Fill in Blank"
        case "listen-repeat": return "Listen & Repeat"
        case "word-building": return "Word Building"
        default: return type.capitalized
        }
    }

    private func activityIconName(for type: String) -> String {
        switch type.lowercased() {
        case "reading": return "book"
        case "spelling": return "textformat.abc"
        case "phonics": return "waveform"
        case "sight-words": return "eye"
        case "quiz": return "questionmark.circle"
        case "matching": return "rectangle.on.rectangle"
        case "fill-in-blank": return "square.and.pencil"
        case "listen-repeat": return "speaker.wave.2"
        case "word-building": return "puzzlepiece"
        default: return "star"
        }
    }
}

// MARK: - Words Flow View

/// Displays a list of words as tappable chips.
private struct WordsFlowView: View {
    let words: [String]

    private let voiceService = VoiceService.shared

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80, maximum: 140), spacing: L2RTheme.Spacing.sm)],
            spacing: L2RTheme.Spacing.sm
        ) {
            ForEach(words, id: \.self) { word in
                Button {
                    Task { await voiceService.speak(word) }
                } label: {
                    Text(word)
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .callout, weight: .bold))
                        .foregroundStyle(L2RTheme.primary)
                        .padding(.horizontal, L2RTheme.Spacing.sm)
                        .padding(.vertical, L2RTheme.Spacing.xs)
                        .background(L2RTheme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small))
                }
                .accessibilityLabel("Word: \(word). Tap to hear.")
            }
        }
    }
}

#Preview("Lesson Player") {
    NavigationStack {
        LessonPlayerView(lessonId: "test-lesson")
    }
}
