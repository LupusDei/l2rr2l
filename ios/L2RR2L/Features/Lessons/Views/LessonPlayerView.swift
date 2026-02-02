import SwiftUI

/// Lesson player for stepping through activities with progress tracking.
struct LessonPlayerView: View {
    @StateObject private var viewModel: LessonPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false

    init(lesson: Lesson, existingProgress: LessonProgress? = nil) {
        _viewModel = StateObject(wrappedValue: LessonPlayerViewModel(
            lesson: lesson,
            existingProgress: existingProgress
        ))
    }

    var body: some View {
        ZStack {
            // Background
            AnimatedBackgroundView()

            if viewModel.isCompleted {
                completionView
            } else {
                lessonContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Exit Lesson?", isPresented: $showExitConfirmation) {
            Button("Keep Learning", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Your progress will be saved.")
        }
    }

    // MARK: - Lesson Content

    private var lessonContent: some View {
        VStack(spacing: 0) {
            // Header with close and progress
            headerView
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.top, L2RTheme.Spacing.sm)

            // Progress indicator
            progressSection
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.top, L2RTheme.Spacing.md)

            Spacer()

            // Current activity content
            if let activity = viewModel.currentActivity {
                ActivityContentView(
                    activity: activity,
                    onComplete: { score in
                        viewModel.completeCurrentActivity(score: score)
                    }
                )
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .id(activity.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            Spacer()

            // Navigation buttons
            navigationButtons
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.bottom, L2RTheme.Spacing.xxl)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Close button
            Button {
                showExitConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .frame(width: L2RTheme.TouchTarget.comfortable, height: L2RTheme.TouchTarget.comfortable)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.8))
                    )
            }
            .accessibilityLabel("Close lesson")

            Spacer()

            // Score display
            HStack(spacing: L2RTheme.Spacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(L2RTheme.Status.warning)
                Text("\(viewModel.totalScore)")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                    .foregroundStyle(L2RTheme.textPrimary)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient.ctaButton)
                        .frame(width: geometry.size.width * viewModel.progressFraction, height: 12)
                        .animation(.easeInOut(duration: L2RTheme.Animation.normal), value: viewModel.progressFraction)
                }
            }
            .frame(height: 12)

            // Activity counter
            Text("Activity \(viewModel.currentActivityIndex + 1) of \(viewModel.totalActivities)")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: L2RTheme.Spacing.lg) {
            // Previous button
            Button {
                withAnimation(L2RTheme.Animation.bounce) {
                    viewModel.goToPrevious()
                }
            } label: {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Previous")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                }
                .foregroundStyle(viewModel.canGoBack ? L2RTheme.primary : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: L2RTheme.TouchTarget.large)
                .background(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .disabled(!viewModel.canGoBack)

            // Next button
            Button {
                withAnimation(L2RTheme.Animation.bounce) {
                    viewModel.goToNext()
                }
            } label: {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Text(viewModel.isLastActivity ? "Finish" : "Next")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .bold))
                    Image(systemName: viewModel.isLastActivity ? "checkmark" : "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: L2RTheme.TouchTarget.large)
                .background(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .fill(viewModel.canGoNext ? LinearGradient.ctaButton : LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                )
                .shadow(
                    color: viewModel.canGoNext ? L2RTheme.CTA.shadow.opacity(0.3) : .clear,
                    radius: 4,
                    x: 0,
                    y: L2RTheme.Shadow.buttonDepth
                )
            }
            .disabled(!viewModel.canGoNext)
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: L2RTheme.Spacing.xxl) {
            Spacer()

            // Celebration emoji
            Text("🎉")
                .font(.system(size: 80))
                .bouncing()

            // Congratulations message
            VStack(spacing: L2RTheme.Spacing.sm) {
                Text("Great Job!")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                    .foregroundStyle(L2RTheme.textPrimary)

                Text("You completed the lesson!")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            // Score summary
            scoreSummary
                .padding(.horizontal, L2RTheme.Spacing.xl)

            Spacer()

            // Done button
            Button {
                dismiss()
            } label: {
                HStack(spacing: L2RTheme.Spacing.sm) {
                    Text("Done")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: L2RTheme.TouchTarget.xlarge)
                .background(LinearGradient.ctaButton)
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
                .shadow(
                    color: L2RTheme.CTA.shadow.opacity(0.4),
                    radius: 6,
                    x: 0,
                    y: L2RTheme.Shadow.buttonDepth
                )
            }
            .padding(.horizontal, L2RTheme.Spacing.xl)
            .padding(.bottom, L2RTheme.Spacing.xxl)
        }
    }

    // MARK: - Score Summary

    private var scoreSummary: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            // Total score
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(L2RTheme.Status.warning)
                Text("\(viewModel.totalScore) points")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                    .foregroundStyle(L2RTheme.textPrimary)
            }

            // Stats grid
            HStack(spacing: L2RTheme.Spacing.xl) {
                statItem(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.completedActivities)",
                    label: "Activities",
                    color: L2RTheme.Status.success
                )

                statItem(
                    icon: "percent",
                    value: "\(viewModel.scorePercentage)%",
                    label: "Score",
                    color: L2RTheme.primary
                )
            }
        }
        .padding(L2RTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.xlarge)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: L2RTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(value)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)
            Text(label)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleLesson = Lesson(
        id: "preview-lesson",
        title: "Learning the Letter A",
        description: "Learn about the letter A",
        subject: .phonics,
        difficulty: .beginner,
        objectives: ["Learn the sound of A"],
        activities: [
            LessonActivity(
                id: "1",
                type: .phonics,
                instructions: "Listen to the sound of the letter A",
                spokenInstructions: nil,
                order: 1,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil,
                word: nil, hint: nil, audioUrl: nil,
                sound: "A", exampleWords: ["Apple", "Ant", "Alligator"], soundPosition: "beginning",
                words: nil, showInContext: nil,
                question: nil, options: nil, correctIndex: nil, explanation: nil,
                pairs: nil, matchType: nil,
                sentence: nil, answer: nil, wordBank: nil,
                phrase: nil, checkPronunciation: nil,
                pattern: nil, onsets: nil
            ),
            LessonActivity(
                id: "2",
                type: .quiz,
                instructions: "Pick the word that starts with A",
                spokenInstructions: nil,
                order: 2,
                points: 10,
                content: nil, imageUrl: nil, readAloud: nil,
                word: nil, hint: nil, audioUrl: nil,
                sound: nil, exampleWords: nil, soundPosition: nil,
                words: nil, showInContext: nil,
                question: "Which word starts with A?",
                options: ["Apple", "Banana", "Cherry"],
                correctIndex: 0,
                explanation: "Apple starts with the letter A!",
                pairs: nil, matchType: nil,
                sentence: nil, answer: nil, wordBank: nil,
                phrase: nil, checkPronunciation: nil,
                pattern: nil, onsets: nil
            )
        ],
        durationMinutes: 5,
        prerequisites: nil,
        tags: ["phonics", "letter-a"],
        thumbnailUrl: nil,
        ageRange: Lesson.AgeRange(min: 4, max: 6),
        createdAt: "2024-01-01",
        updatedAt: "2024-01-01"
    )

    NavigationStack {
        LessonPlayerView(lesson: sampleLesson)
    }
}
