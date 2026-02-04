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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap to view lesson details")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabelText: String {
        var parts: [String] = [lesson.title]
        parts.append("\(lesson.subject.capitalized) lesson")
        if let duration = lesson.durationMinutes {
            parts.append("\(duration) minutes")
        }
        parts.append("\(difficultyLabel) difficulty")
        if let ageMin = lesson.ageMin, let ageMax = lesson.ageMax {
            parts.append("Ages \(ageMin) to \(ageMax)")
        }
        return parts.joined(separator: ", ")
    }

    private var difficultyLabel: String {
        switch lesson.difficulty?.lowercased() {
        case "beginner": return "Beginner"
        case "intermediate": return "Intermediate"
        case "advanced": return "Advanced"
        default: return "Beginner"
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
            if let duration = lesson.durationMinutes {
                durationBadge(duration)
            }

            if let ageMin = lesson.ageMin, let ageMax = lesson.ageMax {
                ageRangeBadge(min: ageMin, max: ageMax)
            }
        }
    }

    private func durationBadge(_ minutes: Int) -> some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text("\(minutes) min")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
        }
        .foregroundStyle(L2RTheme.textSecondary)
    }

    private func ageRangeBadge(min: Int, max: Int) -> some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Image(systemName: "person.fill")
                .font(.system(size: 10))
            Text("Ages \(min)-\(max)")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
        }
        .foregroundStyle(L2RTheme.textSecondary)
    }

    @ViewBuilder
    private var objectivesPreview: some View {
        if let objectives = lesson.objectives, !objectives.isEmpty {
            let objectiveTexts = objectives.compactMap { $0.text ?? $0.description }
            if !objectiveTexts.isEmpty {
                Text(objectiveTexts.prefix(2).joined(separator: " • "))
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                    .foregroundStyle(L2RTheme.textMuted)
                    .lineLimit(1)
            }
        }
    }

    private var subjectEmoji: String {
        switch lesson.subject.lowercased() {
        case "phonics": return "🔤"
        case "spelling": return "✏️"
        case "sight-words", "sightwords": return "👀"
        case "reading": return "📖"
        case "word-families", "wordfamilies": return "👨‍👩‍👧‍👦"
        case "vocabulary": return "📚"
        case "comprehension": return "🧠"
        default: return "📖"
        }
    }

    private var subjectColor: Color {
        switch lesson.subject.lowercased() {
        case "phonics": return L2RTheme.Game.phonicsStart
        case "spelling": return L2RTheme.Game.spellingStart
        case "sight-words", "sightwords": return L2RTheme.Accent.purple
        case "reading": return L2RTheme.Logo.blue
        case "word-families", "wordfamilies": return L2RTheme.Accent.orange
        case "vocabulary": return L2RTheme.Logo.green
        case "comprehension": return L2RTheme.Accent.teal
        default: return L2RTheme.primary
        }
    }

    private var difficultyLevel: Int {
        switch lesson.difficulty?.lowercased() {
        case "beginner": return 1
        case "intermediate": return 2
        case "advanced": return 3
        default: return 1
        }
    }
}

// Preview removed due to type incompatibility
