import SwiftUI

// MARK: - Badge Style

enum BadgeStyle {
    case success
    case warning
    case error
    case info
    case count

    var backgroundColor: Color {
        switch self {
        case .success: return L2RTheme.Status.success
        case .warning: return L2RTheme.Status.warning
        case .error: return L2RTheme.Status.error
        case .info: return L2RTheme.Status.info
        case .count: return L2RTheme.primary
        }
    }

    var foregroundColor: Color {
        switch self {
        case .warning: return L2RTheme.textPrimary
        default: return .white
        }
    }
}

// MARK: - Badge

struct Badge: View {
    let text: String
    let style: BadgeStyle

    var body: some View {
        Text(text)
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .semibold))
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, L2RTheme.Spacing.xs)
            .padding(.vertical, L2RTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
            )
    }
}

// MARK: - Count Badge

struct CountBadge: View {
    let count: Int
    var maxCount: Int = 99
    var color: Color = L2RTheme.Status.error

    private var displayText: String {
        count > maxCount ? "\(maxCount)+" : "\(count)"
    }

    var body: some View {
        Text(displayText)
            .font(L2RTheme.Typography.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(minWidth: 20, minHeight: 20)
            .padding(.horizontal, count > 9 ? 4 : 0)
            .background(
                Circle()
                    .fill(color)
            )
    }
}

// MARK: - Difficulty Stars

struct DifficultyStars: View {
    let level: Int
    var maxLevel: Int = 3
    var filledColor: Color = L2RTheme.Status.warning
    var emptyColor: Color = L2RTheme.border

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.xxxs) {
            ForEach(1...maxLevel, id: \.self) { index in
                Image(systemName: index <= level ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundStyle(index <= level ? filledColor : emptyColor)
            }
        }
    }
}

// MARK: - Tag

struct Tag: View {
    let text: String
    var color: Color = L2RTheme.primary
    var textColor: Color? = nil

    private var resolvedTextColor: Color {
        textColor ?? .white
    }

    var body: some View {
        Text(text)
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small, weight: .medium))
            .foregroundStyle(resolvedTextColor)
            .padding(.horizontal, L2RTheme.Spacing.sm)
            .padding(.vertical, L2RTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

// MARK: - Tag Group

struct TagGroup: View {
    let tags: [(text: String, color: Color)]
    var spacing: CGFloat = L2RTheme.Spacing.xs

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(tags.indices, id: \.self) { index in
                Tag(text: tags[index].text, color: tags[index].color)
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subview.sizeThatFits(.unspecified))
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

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
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Subject Tag Presets

extension Tag {
    static func subject(_ text: String) -> Tag {
        Tag(text: text, color: L2RTheme.Accent.purple)
    }

    static func ageRange(_ text: String) -> Tag {
        Tag(text: text, color: L2RTheme.Accent.teal)
    }

    static func skillLevel(_ text: String) -> Tag {
        Tag(text: text, color: L2RTheme.Accent.orange)
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    VStack(spacing: L2RTheme.Spacing.md) {
        HStack(spacing: L2RTheme.Spacing.sm) {
            Badge(text: "Success", style: .success)
            Badge(text: "Warning", style: .warning)
            Badge(text: "Error", style: .error)
            Badge(text: "Info", style: .info)
        }
    }
    .padding()
}

#Preview("Count Badges") {
    HStack(spacing: L2RTheme.Spacing.xl) {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.title)
                .foregroundStyle(L2RTheme.textSecondary)
            CountBadge(count: 3)
                .offset(x: 8, y: -8)
        }

        ZStack(alignment: .topTrailing) {
            Image(systemName: "envelope.fill")
                .font(.title)
                .foregroundStyle(L2RTheme.textSecondary)
            CountBadge(count: 42)
                .offset(x: 12, y: -8)
        }

        ZStack(alignment: .topTrailing) {
            Image(systemName: "cart.fill")
                .font(.title)
                .foregroundStyle(L2RTheme.textSecondary)
            CountBadge(count: 150)
                .offset(x: 16, y: -8)
        }
    }
    .padding()
}

#Preview("Difficulty Stars") {
    VStack(alignment: .leading, spacing: L2RTheme.Spacing.md) {
        HStack {
            Text("Easy:")
            DifficultyStars(level: 1)
        }
        HStack {
            Text("Medium:")
            DifficultyStars(level: 2)
        }
        HStack {
            Text("Hard:")
            DifficultyStars(level: 3)
        }
    }
    .padding()
}

#Preview("Tags") {
    VStack(alignment: .leading, spacing: L2RTheme.Spacing.md) {
        Text("Subject Tags")
            .font(.headline)
        HStack(spacing: L2RTheme.Spacing.xs) {
            Tag.subject("Reading")
            Tag.subject("Phonics")
            Tag.subject("Spelling")
        }

        Text("Age Ranges")
            .font(.headline)
        HStack(spacing: L2RTheme.Spacing.xs) {
            Tag.ageRange("3-4 years")
            Tag.ageRange("5-6 years")
            Tag.ageRange("7-8 years")
        }

        Text("Skill Levels")
            .font(.headline)
        HStack(spacing: L2RTheme.Spacing.xs) {
            Tag.skillLevel("Beginner")
            Tag.skillLevel("Intermediate")
            Tag.skillLevel("Advanced")
        }
    }
    .padding()
}

#Preview("Tag Group with Flow Layout") {
    TagGroup(tags: [
        ("Reading", L2RTheme.Accent.purple),
        ("Phonics", L2RTheme.Accent.teal),
        ("Spelling", L2RTheme.Accent.orange),
        ("Vocabulary", L2RTheme.Accent.pink),
        ("Comprehension", L2RTheme.Accent.coral),
        ("Grammar", L2RTheme.primary)
    ])
    .frame(width: 250)
    .padding()
}
