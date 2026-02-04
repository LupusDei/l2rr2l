import SwiftUI

/// Detailed view for a lesson showing all information and start/continue actions.
struct LessonDetailView: View {
    let lesson: Lesson
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Computed helpers for optionals
    private var activities: [LessonActivity] {
        lesson.activities ?? []
    }

    private var objectives: [LessonObjective] {
        lesson.objectives ?? []
    }

    private var durationMinutes: Int {
        lesson.durationMinutes ?? 15
    }

    private var descriptionText: String {
        lesson.description ?? "Learn and practice new skills with fun activities."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.lg) {
                // Header with subject icon and title
                headerSection

                // Metadata row (difficulty, duration, age)
                metadataSection

                // Description
                descriptionSection

                // Learning objectives
                if !objectives.isEmpty {
                    objectivesSection
                }

                // Activities preview
                if !activities.isEmpty {
                    activitiesSection
                }

                Spacer(minLength: L2RTheme.Spacing.xxl)

                // Start button
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
                Text(subjectDisplayName)
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

            Image(systemName: subjectIconName)
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
                Text("\(durationMinutes) min")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
            }

            // Age range
            if let ageMin = lesson.ageMin, let ageMax = lesson.ageMax {
                HStack(spacing: L2RTheme.Spacing.xxs) {
                    Image(systemName: "person.2")
                        .foregroundStyle(L2RTheme.textSecondary)
                    Text("Ages \(ageMin)-\(ageMax)")
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
                Image(systemName: index < difficultyStarCount ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundStyle(index < difficultyStarCount ? L2RTheme.Status.warning : L2RTheme.textSecondary.opacity(0.3))
            }
            Text(difficultyDisplayName)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        Text(descriptionText)
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
                ForEach(objectives.indices, id: \.self) { index in
                    let objective = objectives[index]
                    HStack(alignment: .top, spacing: L2RTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(L2RTheme.Status.success)

                        Text(objective.text ?? objective.description ?? "Complete this activity")
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
                Text("\(activities.count) Activities")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                    .foregroundStyle(L2RTheme.textPrimary)
            } icon: {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(L2RTheme.primary)
            }

            // Activity type summary
            let activityTypes = Dictionary(grouping: activities, by: { $0.type ?? "activity" })

            LessonFlowLayout(spacing: L2RTheme.Spacing.xs) {
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

    private func activityTypeBadge(type: String, count: Int) -> some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Image(systemName: activityIconName(for: type))
                .font(.system(size: 12))
            Text("\(count) \(activityDisplayName(for: type))")
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
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
                Text("Start Lesson")
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

    // MARK: - Subject Styling

    private var subjectDisplayName: String {
        switch lesson.subject.lowercased() {
        case "phonics": return "Phonics"
        case "spelling": return "Spelling"
        case "sight-words", "sightwords": return "Sight Words"
        case "reading": return "Reading"
        case "word-families", "wordfamilies": return "Word Families"
        case "vocabulary": return "Vocabulary"
        case "comprehension": return "Comprehension"
        default: return lesson.subject.capitalized
        }
    }

    private var subjectIconName: String {
        switch lesson.subject.lowercased() {
        case "phonics": return "waveform"
        case "spelling": return "textformat.abc"
        case "sight-words", "sightwords": return "eye"
        case "reading": return "book"
        case "word-families", "wordfamilies": return "rectangle.3.group"
        case "vocabulary": return "character.book.closed"
        case "comprehension": return "brain.head.profile"
        default: return "book"
        }
    }

    private var subjectColor: Color {
        switch lesson.subject.lowercased() {
        case "phonics": return L2RTheme.Game.phonicsStart
        case "spelling": return L2RTheme.Game.spellingStart
        case "reading": return L2RTheme.Game.readAloudStart
        case "sight-words", "sightwords": return L2RTheme.Game.memoryStart
        case "word-families", "wordfamilies": return L2RTheme.Game.builderStart
        case "vocabulary": return L2RTheme.Accent.teal
        case "comprehension": return L2RTheme.Accent.purple
        default: return L2RTheme.primary
        }
    }

    private var subjectGradient: LinearGradient {
        switch lesson.subject.lowercased() {
        case "phonics": return .phonicsGame
        case "spelling": return .spellingGame
        case "reading": return .readAloudGame
        case "sight-words", "sightwords": return .memoryGame
        case "word-families", "wordfamilies": return .wordBuilder
        case "vocabulary": return LinearGradient(colors: [L2RTheme.Accent.teal, L2RTheme.Status.success], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "comprehension": return LinearGradient(colors: [L2RTheme.Accent.purple, L2RTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return .ctaButton
        }
    }

    // MARK: - Difficulty Helpers

    private var difficultyDisplayName: String {
        switch lesson.difficulty?.lowercased() {
        case "beginner": return "Easy"
        case "intermediate": return "Medium"
        case "advanced": return "Hard"
        default: return "Easy"
        }
    }

    private var difficultyStarCount: Int {
        switch lesson.difficulty?.lowercased() {
        case "beginner": return 1
        case "intermediate": return 2
        case "advanced": return 3
        default: return 1
        }
    }

    // MARK: - Activity Helpers

    private func activityDisplayName(for type: String) -> String {
        switch type.lowercased() {
        case "reading": return "Reading"
        case "spelling": return "Spelling"
        case "phonics": return "Phonics"
        case "sight-words", "sightwords": return "Sight Words"
        case "quiz": return "Quiz"
        case "matching": return "Matching"
        case "fill-in-blank", "fillinblank": return "Fill in Blank"
        case "listen-repeat", "listenrepeat": return "Listen & Repeat"
        case "word-building", "wordbuilding": return "Word Building"
        default: return type.capitalized
        }
    }

    private func activityIconName(for type: String) -> String {
        switch type.lowercased() {
        case "reading": return "book"
        case "spelling": return "textformat.abc"
        case "phonics": return "waveform"
        case "sight-words", "sightwords": return "eye"
        case "quiz": return "questionmark.circle"
        case "matching": return "rectangle.on.rectangle"
        case "fill-in-blank", "fillinblank": return "square.and.pencil"
        case "listen-repeat", "listenrepeat": return "speaker.wave.2"
        case "word-building", "wordbuilding": return "puzzlepiece"
        default: return "star"
        }
    }
}

// MARK: - Flow Layout

/// Simple flow layout for activity badges
private struct LessonFlowLayout: Layout {
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

// Preview removed due to type incompatibility
