import SwiftUI

/// A large, colorful card for the child-friendly lesson browse view.
struct LessonBrowseCard: View {
    let lesson: Lesson
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: L2RTheme.Spacing.sm) {
                // Large emoji icon
                Text(subjectEmoji)
                    .font(.system(size: 48))
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.3))
                    )

                // Title
                Text(lesson.title)
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .callout, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Difficulty stars
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Image(systemName: index < difficultyLevel ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(index < difficultyLevel ? .yellow : .white.opacity(0.4))
                    }
                }

                // Subject tag
                Text(subjectDisplayName)
                    .font(L2RTheme.Typography.Scaled.system(.caption, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, L2RTheme.Spacing.sm)
                    .padding(.vertical, L2RTheme.Spacing.xxxs)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(L2RTheme.Spacing.md)
            .padding(.vertical, L2RTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.xlarge)
                    .fill(
                        LinearGradient(
                            colors: [subjectColor, subjectColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: subjectColor.opacity(0.4), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lesson.title), \(subjectDisplayName), \(difficultyLabel) difficulty")
        .accessibilityHint("Double tap to view lesson")
        .accessibilityAddTraits(.isButton)
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

    private var difficultyLevel: Int {
        switch lesson.difficulty?.lowercased() {
        case "beginner": return 1
        case "intermediate": return 2
        case "advanced": return 3
        default: return 1
        }
    }

    private var difficultyLabel: String {
        switch lesson.difficulty?.lowercased() {
        case "beginner": return "Beginner"
        case "intermediate": return "Intermediate"
        case "advanced": return "Advanced"
        default: return "Beginner"
        }
    }
}
