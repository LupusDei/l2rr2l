import SwiftUI

/// A card component displaying lesson information.
struct LessonCard: View {
    let lesson: Lesson
    var onTap: (() -> Void)?

    var body: some View {
        BaseCard(action: onTap) {
            HStack(spacing: L2RTheme.Spacing.md) {
                subjectIcon

                VStack(alignment: .leading, spacing: L2RTheme.Spacing.xxs) {
                    titleRow
                    metadataRow
                    objectivesPreview
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(L2RTheme.textSecondary)
            }
        }
    }

    private var subjectIcon: some View {
        ZStack {
            Circle()
                .fill(subjectColor.opacity(0.2))
                .frame(width: 56, height: 56)

            Text(subjectEmoji)
                .font(.system(size: 24))
        }
    }

    private var titleRow: some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            Text(lesson.title)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)
                .lineLimit(1)

            difficultyStars
        }
    }

    private var difficultyStars: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Image(systemName: index < difficultyLevel ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(index < difficultyLevel ? L2RTheme.Status.warning : L2RTheme.textMuted.opacity(0.3))
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            durationBadge

            if let ageRange = lesson.ageRange {
                ageRangeBadge(ageRange)
            }
        }
    }

    private var durationBadge: some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text("\(lesson.durationMinutes) min")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
        }
        .foregroundStyle(L2RTheme.textSecondary)
    }

    private func ageRangeBadge(_ ageRange: Lesson.AgeRange) -> some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Image(systemName: "person.fill")
                .font(.system(size: 10))
            Text("Ages \(ageRange.min)-\(ageRange.max)")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
        }
        .foregroundStyle(L2RTheme.textSecondary)
    }

    @ViewBuilder
    private var objectivesPreview: some View {
        if !lesson.objectives.isEmpty {
            Text(lesson.objectives.prefix(2).joined(separator: " • "))
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                .foregroundStyle(L2RTheme.textMuted)
                .lineLimit(1)
        }
    }

    private var subjectEmoji: String {
        switch lesson.subject {
        case .phonics: return "🔤"
        case .spelling: return "✏️"
        case .sightWords: return "👀"
        case .reading: return "📖"
        case .wordFamilies: return "👨‍👩‍👧‍👦"
        case .vocabulary: return "📚"
        case .comprehension: return "🧠"
        }
    }

    private var subjectColor: Color {
        switch lesson.subject {
        case .phonics: return L2RTheme.Game.phonicsStart
        case .spelling: return L2RTheme.Game.spellingStart
        case .sightWords: return L2RTheme.Accent.purple
        case .reading: return L2RTheme.Logo.blue
        case .wordFamilies: return L2RTheme.Accent.orange
        case .vocabulary: return L2RTheme.Logo.green
        case .comprehension: return L2RTheme.Accent.teal
        }
    }

    private var difficultyLevel: Int {
        switch lesson.difficulty {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

#Preview {
    let sampleLesson = Lesson(
        id: "lesson-1",
        title: "Letter Sounds A-E",
        description: "Learn the sounds of letters A through E",
        subject: .phonics,
        difficulty: .beginner,
        objectives: ["Identify letter sounds", "Match sounds to letters", "Practice pronunciation"],
        activities: [],
        durationMinutes: 15,
        prerequisites: nil,
        tags: ["phonics", "beginner"],
        thumbnailUrl: nil,
        ageRange: Lesson.AgeRange(min: 4, max: 6),
        createdAt: "2026-01-01",
        updatedAt: "2026-01-01"
    )

    ScrollView {
        VStack(spacing: L2RTheme.Spacing.md) {
            LessonCard(lesson: sampleLesson) {
                print("Tapped lesson")
            }

            LessonCard(
                lesson: Lesson(
                    id: "lesson-2",
                    title: "Spelling Practice",
                    description: "Practice spelling common words",
                    subject: .spelling,
                    difficulty: .intermediate,
                    objectives: ["Spell 10 new words", "Use words in sentences"],
                    activities: [],
                    durationMinutes: 20,
                    prerequisites: nil,
                    tags: nil,
                    thumbnailUrl: nil,
                    ageRange: Lesson.AgeRange(min: 5, max: 7),
                    createdAt: "2026-01-01",
                    updatedAt: "2026-01-01"
                )
            )

            LessonCard(
                lesson: Lesson(
                    id: "lesson-3",
                    title: "Advanced Reading",
                    description: "Read and comprehend longer passages",
                    subject: .comprehension,
                    difficulty: .advanced,
                    objectives: ["Read a full story", "Answer comprehension questions", "Identify main ideas"],
                    activities: [],
                    durationMinutes: 30,
                    prerequisites: nil,
                    tags: nil,
                    thumbnailUrl: nil,
                    ageRange: Lesson.AgeRange(min: 6, max: 8),
                    createdAt: "2026-01-01",
                    updatedAt: "2026-01-01"
                )
            )
        }
        .padding()
    }
    .background(L2RTheme.background)
}
