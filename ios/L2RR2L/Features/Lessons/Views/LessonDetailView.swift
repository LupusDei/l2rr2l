import SwiftUI

/// Detailed view for a lesson showing all information and start/continue actions.
struct LessonDetailView: View {
    let lesson: Lesson
    let progress: LessonProgress?
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var isInProgress: Bool {
        progress?.status == .inProgress
    }

    private var isCompleted: Bool {
        progress?.status == .completed
    }

    private var progressPercentage: Double {
        guard let progress = progress, !lesson.activities.isEmpty else { return 0 }
        let completedCount = progress.activityProgress.filter { $0.completed }.count
        return Double(completedCount) / Double(lesson.activities.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.lg) {
                // Header with subject icon and title
                headerSection

                // Metadata row (difficulty, duration, age)
                metadataSection

                // Progress indicator (if in progress)
                if isInProgress {
                    progressSection
                }

                // Description
                descriptionSection

                // Learning objectives
                objectivesSection

                // Activities preview
                activitiesSection

                Spacer(minLength: L2RTheme.Spacing.xxl)

                // Start/Continue button
                actionButton
            }
            .padding(L2RTheme.Spacing.lg)
        }
        .background(L2RTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: L2RTheme.Spacing.xxs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(L2RTheme.primary)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top, spacing: L2RTheme.Spacing.md) {
            // Subject icon
            subjectIcon

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxs) {
                // Subject label
                Text(lesson.subject.displayName)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
                    .foregroundStyle(subjectColor)
                    .textCase(.uppercase)

                // Title
                Text(lesson.title)
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                    .foregroundStyle(L2RTheme.textPrimary)
            }

            Spacer()
        }
    }

    private var subjectIcon: some View {
        ZStack {
            Circle()
                .fill(subjectGradient)
                .frame(width: 56, height: 56)

            Image(systemName: lesson.subject.iconName)
                .font(.system(size: 24))
                .foregroundStyle(.white)
        }
        .shadow(color: subjectColor.opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        HStack(spacing: L2RTheme.Spacing.lg) {
            // Difficulty stars
            difficultyView

            // Duration
            HStack(spacing: L2RTheme.Spacing.xxs) {
                Image(systemName: "clock")
                    .foregroundStyle(L2RTheme.textSecondary)
                Text("\(lesson.durationMinutes) min")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            // Age range
            if let ageRange = lesson.ageRange {
                HStack(spacing: L2RTheme.Spacing.xxs) {
                    Image(systemName: "person.2")
                        .foregroundStyle(L2RTheme.textSecondary)
                    Text("Ages \(ageRange.min)-\(ageRange.max)")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                        .foregroundStyle(L2RTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, L2RTheme.Spacing.sm)
    }

    private var difficultyView: some View {
        HStack(spacing: L2RTheme.Spacing.xxxs) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < lesson.difficulty.starCount ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundStyle(index < lesson.difficulty.starCount ? L2RTheme.Status.warning : L2RTheme.textSecondary.opacity(0.3))
            }
            Text(lesson.difficulty.displayName)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
            HStack {
                Text("In Progress")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .semibold))
                    .foregroundStyle(L2RTheme.primary)

                Spacer()

                Text("\(Int(progressPercentage * 100))% complete")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
                        .fill(L2RTheme.border)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small)
                        .fill(LinearGradient(
                            colors: [L2RTheme.primary, L2RTheme.Accent.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(L2RTheme.Spacing.md)
        .background(L2RTheme.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        Text(lesson.description)
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .regular))
            .foregroundStyle(L2RTheme.textPrimary)
            .lineSpacing(4)
    }

    // MARK: - Objectives Section

    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            Label {
                Text("What you'll learn")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)
            } icon: {
                Image(systemName: "checklist")
                    .foregroundStyle(L2RTheme.Status.success)
            }

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
                ForEach(lesson.objectives, id: \.self) { objective in
                    HStack(alignment: .top, spacing: L2RTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(L2RTheme.Status.success)

                        Text(objective)
                            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .regular))
                            .foregroundStyle(L2RTheme.textPrimary)
                    }
                }
            }
            .padding(.leading, L2RTheme.Spacing.xxs)
        }
        .padding(L2RTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(L2RTheme.Status.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
    }

    // MARK: - Activities Section

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.sm) {
            Label {
                Text("\(lesson.activities.count) Activities")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)
            } icon: {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(L2RTheme.primary)
            }

            // Activity type summary
            let activityTypes = Dictionary(grouping: lesson.activities, by: { $0.type })

            FlowLayout(spacing: L2RTheme.Spacing.xs) {
                ForEach(Array(activityTypes.keys), id: \.self) { type in
                    if let count = activityTypes[type]?.count {
                        activityTypeBadge(type: type, count: count)
                    }
                }
            }
        }
        .padding(L2RTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(L2RTheme.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
    }

    private func activityTypeBadge(type: ActivityType, count: Int) -> some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Image(systemName: type.iconName)
                .font(.system(size: 12))
            Text("\(count) \(type.displayName)")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
        }
        .foregroundStyle(L2RTheme.primary)
        .padding(.horizontal, L2RTheme.Spacing.sm)
        .padding(.vertical, L2RTheme.Spacing.xxs)
        .background(L2RTheme.primary.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            onStart()
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                Image(systemName: isInProgress ? "play.fill" : isCompleted ? "arrow.counterclockwise" : "play.fill")
                    .font(.system(size: 18))
                Text(buttonTitle)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
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
    }

    private var buttonTitle: String {
        if isCompleted {
            return "Play Again"
        } else if isInProgress {
            return "Continue Lesson"
        } else {
            return "Start Lesson"
        }
    }

    // MARK: - Subject Styling

    private var subjectColor: Color {
        switch lesson.subject {
        case .phonics:
            return L2RTheme.Game.phonicsStart
        case .spelling:
            return L2RTheme.Game.spellingStart
        case .reading:
            return L2RTheme.Game.readAloudStart
        case .sightWords:
            return L2RTheme.Game.memoryStart
        case .wordFamilies:
            return L2RTheme.Game.builderStart
        case .vocabulary:
            return L2RTheme.Accent.teal
        case .comprehension:
            return L2RTheme.Accent.purple
        }
    }

    private var subjectGradient: LinearGradient {
        switch lesson.subject {
        case .phonics:
            return .phonicsGame
        case .spelling:
            return .spellingGame
        case .reading:
            return .readAloudGame
        case .sightWords:
            return .memoryGame
        case .wordFamilies:
            return .wordBuilder
        case .vocabulary:
            return LinearGradient(colors: [L2RTheme.Accent.teal, L2RTheme.Status.success], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .comprehension:
            return LinearGradient(colors: [L2RTheme.Accent.purple, L2RTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Flow Layout

/// Simple flow layout for activity badges
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Model Extensions

extension LessonSubject {
    var displayName: String {
        switch self {
        case .phonics: return "Phonics"
        case .spelling: return "Spelling"
        case .sightWords: return "Sight Words"
        case .reading: return "Reading"
        case .wordFamilies: return "Word Families"
        case .vocabulary: return "Vocabulary"
        case .comprehension: return "Comprehension"
        }
    }

    var iconName: String {
        switch self {
        case .phonics: return "waveform"
        case .spelling: return "textformat.abc"
        case .sightWords: return "eye"
        case .reading: return "book"
        case .wordFamilies: return "rectangle.3.group"
        case .vocabulary: return "character.book.closed"
        case .comprehension: return "brain.head.profile"
        }
    }
}

extension DifficultyLevel {
    var displayName: String {
        switch self {
        case .beginner: return "Easy"
        case .intermediate: return "Medium"
        case .advanced: return "Hard"
        }
    }

    var starCount: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

extension ActivityType {
    var displayName: String {
        switch self {
        case .reading: return "Reading"
        case .spelling: return "Spelling"
        case .phonics: return "Phonics"
        case .sightWords: return "Sight Words"
        case .quiz: return "Quiz"
        case .matching: return "Matching"
        case .fillInBlank: return "Fill in Blank"
        case .listenRepeat: return "Listen & Repeat"
        case .wordBuilding: return "Word Building"
        }
    }

    var iconName: String {
        switch self {
        case .reading: return "book"
        case .spelling: return "textformat.abc"
        case .phonics: return "waveform"
        case .sightWords: return "eye"
        case .quiz: return "questionmark.circle"
        case .matching: return "rectangle.on.rectangle"
        case .fillInBlank: return "square.and.pencil"
        case .listenRepeat: return "speaker.wave.2"
        case .wordBuilding: return "puzzlepiece"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LessonDetailView(
            lesson: Lesson(
                id: "lesson-1",
                title: "Phonics Basics",
                description: "Learn the sounds that letters make and how to blend them together to form words. This foundational lesson covers the alphabet sounds.",
                subject: .phonics,
                difficulty: .beginner,
                objectives: [
                    "Learn letter sounds A-Z",
                    "Practice beginning sounds",
                    "Blend simple CVC words"
                ],
                activities: [
                    LessonActivity(id: "a1", type: .phonics, instructions: "Listen to the sound", spokenInstructions: nil, order: 1, points: 10, content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: "a", exampleWords: ["apple", "ant"], soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil),
                    LessonActivity(id: "a2", type: .quiz, instructions: "Answer the question", spokenInstructions: nil, order: 2, points: 10, content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: "What sound does A make?", options: ["ah", "buh", "cuh"], correctIndex: 0, explanation: nil, pairs: nil, matchType: nil, sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil),
                    LessonActivity(id: "a3", type: .matching, instructions: "Match the sounds", spokenInstructions: nil, order: 3, points: 10, content: nil, imageUrl: nil, readAloud: nil, word: nil, hint: nil, audioUrl: nil, sound: nil, exampleWords: nil, soundPosition: nil, words: nil, showInContext: nil, question: nil, options: nil, correctIndex: nil, explanation: nil, pairs: [["a", "apple"], ["b", "ball"]], matchType: "sound-word", sentence: nil, answer: nil, wordBank: nil, phrase: nil, checkPronunciation: nil, pattern: nil, onsets: nil)
                ],
                durationMinutes: 15,
                prerequisites: nil,
                tags: ["phonics", "beginner"],
                thumbnailUrl: nil,
                ageRange: Lesson.AgeRange(min: 4, max: 6),
                createdAt: "2024-01-01",
                updatedAt: "2024-01-01"
            ),
            progress: LessonProgress(
                lessonId: "lesson-1",
                childId: "child-1",
                status: .inProgress,
                currentActivityIndex: 1,
                activityProgress: [
                    ActivityProgress(activityId: "a1", completed: true, score: 10, attempts: 1, timeSpentSeconds: 60, completedAt: "2024-01-01")
                ],
                overallScore: nil,
                totalTimeSeconds: 120,
                startedAt: "2024-01-01",
                completedAt: nil
            ),
            onStart: {}
        )
    }
}
