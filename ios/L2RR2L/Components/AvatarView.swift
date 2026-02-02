import SwiftUI

// MARK: - Avatar Size

/// Available sizes for the avatar component
public enum AvatarSize: CGFloat, CaseIterable {
    /// Small size (32pt) - for lists
    case small = 32
    /// Medium size (48pt) - for headers
    case medium = 48
    /// Large size (80pt) - for profile screens
    case large = 80
    /// Extra large size (120pt) - for avatar selection
    case xlarge = 120

    /// Font size for the emoji based on avatar size
    var emojiSize: CGFloat {
        switch self {
        case .small: return 18
        case .medium: return 28
        case .large: return 48
        case .xlarge: return 72
        }
    }

    /// Border width based on avatar size
    var borderWidth: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 2.5
        case .large: return 3
        case .xlarge: return 4
        }
    }

    /// Selection ring width based on avatar size
    var selectionRingWidth: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        case .xlarge: return 5
        }
    }

    /// Selection ring offset based on avatar size
    var selectionRingOffset: CGFloat {
        switch self {
        case .small: return 3
        case .medium: return 4
        case .large: return 5
        case .xlarge: return 6
        }
    }
}

// MARK: - Avatar Emoji

/// Available animal emoji options for avatars
public enum AvatarEmoji: String, CaseIterable, Codable {
    case bear = "🐻"
    case bunny = "🐰"
    case fox = "🦊"
    case owl = "🦉"
    case cat = "🐱"
    case dog = "🐶"
    case panda = "🐼"
    case lion = "🦁"

    /// Display name for the avatar
    var displayName: String {
        switch self {
        case .bear: return "Bear"
        case .bunny: return "Bunny"
        case .fox: return "Fox"
        case .owl: return "Owl"
        case .cat: return "Cat"
        case .dog: return "Dog"
        case .panda: return "Panda"
        case .lion: return "Lion"
        }
    }

    /// Background color for this avatar
    var backgroundColor: Color {
        switch self {
        case .bear: return Color(hex: "#8B4513").opacity(0.2)
        case .bunny: return Color(hex: "#FFB6C1").opacity(0.3)
        case .fox: return Color(hex: "#FF8C00").opacity(0.2)
        case .owl: return Color(hex: "#DEB887").opacity(0.3)
        case .cat: return Color(hex: "#FFD700").opacity(0.2)
        case .dog: return Color(hex: "#D2691E").opacity(0.2)
        case .panda: return Color(hex: "#E8E8E8")
        case .lion: return Color(hex: "#FFA500").opacity(0.25)
        }
    }

    /// Initialize from string (for API compatibility)
    init?(from string: String) {
        if let emoji = AvatarEmoji(rawValue: string) {
            self = emoji
        } else if let emoji = AvatarEmoji.allCases.first(where: { $0.displayName.lowercased() == string.lowercased() }) {
            self = emoji
        } else {
            return nil
        }
    }
}

// MARK: - Avatar View

/// A circular avatar component displaying animal emojis for child profiles.
/// Supports multiple sizes, optional borders, and animated selection states.
public struct AvatarView: View {
    let emoji: AvatarEmoji
    let size: AvatarSize
    var isSelected: Bool = false
    var showBorder: Bool = true
    var borderColor: Color = L2RTheme.border
    var selectionColor: Color = L2RTheme.primary

    @State private var selectionScale: CGFloat = 1.0
    @State private var checkmarkOpacity: Double = 0

    public init(
        emoji: AvatarEmoji,
        size: AvatarSize,
        isSelected: Bool = false,
        showBorder: Bool = true,
        borderColor: Color = L2RTheme.border,
        selectionColor: Color = L2RTheme.primary
    ) {
        self.emoji = emoji
        self.size = size
        self.isSelected = isSelected
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.selectionColor = selectionColor
    }

    /// Convenience initializer from string
    public init?(
        emojiString: String,
        size: AvatarSize,
        isSelected: Bool = false,
        showBorder: Bool = true,
        borderColor: Color = L2RTheme.border,
        selectionColor: Color = L2RTheme.primary
    ) {
        guard let avatarEmoji = AvatarEmoji(from: emojiString) else {
            return nil
        }
        self.emoji = avatarEmoji
        self.size = size
        self.isSelected = isSelected
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.selectionColor = selectionColor
    }

    public var body: some View {
        ZStack {
            // Selection ring (behind avatar)
            if isSelected {
                Circle()
                    .stroke(selectionColor, lineWidth: size.selectionRingWidth)
                    .frame(
                        width: size.rawValue + size.selectionRingOffset * 2,
                        height: size.rawValue + size.selectionRingOffset * 2
                    )
                    .scaleEffect(selectionScale)
            }

            // Avatar circle with emoji
            Circle()
                .fill(emoji.backgroundColor)
                .frame(width: size.rawValue, height: size.rawValue)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? selectionColor : (showBorder ? borderColor : Color.clear),
                            lineWidth: showBorder || isSelected ? size.borderWidth : 0
                        )
                )
                .overlay(
                    Text(emoji.rawValue)
                        .font(.system(size: size.emojiSize))
                )

            // Checkmark badge for selection (only on larger sizes)
            if isSelected && size.rawValue >= AvatarSize.large.rawValue {
                checkmarkBadge
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                playSelectionAnimation()
            } else {
                resetAnimation()
            }
        }
        .onAppear {
            if isSelected {
                selectionScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }

    // MARK: - Checkmark Badge

    private var checkmarkBadge: some View {
        let badgeSize: CGFloat = size == .xlarge ? 32 : 24

        return Circle()
            .fill(selectionColor)
            .frame(width: badgeSize, height: badgeSize)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: badgeSize * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: selectionColor.opacity(0.4), radius: 4, x: 0, y: 2)
            .offset(x: size.rawValue * 0.35, y: -size.rawValue * 0.35)
            .opacity(checkmarkOpacity)
    }

    // MARK: - Animations

    private func playSelectionAnimation() {
        // Pulse the selection ring
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            selectionScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectionScale = 1.0
            }
        }

        // Fade in checkmark
        withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
            checkmarkOpacity = 1.0
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            selectionScale = 1.0
            checkmarkOpacity = 0
        }
    }
}

// MARK: - Avatar Selection Grid

/// A grid view for selecting an avatar from available options
public struct AvatarSelectionGrid: View {
    @Binding var selectedEmoji: AvatarEmoji?
    var columns: Int = 4
    var spacing: CGFloat = L2RTheme.Spacing.md

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }

    public init(selectedEmoji: Binding<AvatarEmoji?>, columns: Int = 4, spacing: CGFloat = L2RTheme.Spacing.md) {
        self._selectedEmoji = selectedEmoji
        self.columns = columns
        self.spacing = spacing
    }

    public var body: some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(AvatarEmoji.allCases, id: \.self) { emoji in
                AvatarView(
                    emoji: emoji,
                    size: .xlarge,
                    isSelected: selectedEmoji == emoji
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedEmoji = emoji
                    }
                }
                .accessibilityLabel("\(emoji.displayName) avatar")
                .accessibilityAddTraits(selectedEmoji == emoji ? .isSelected : [])
            }
        }
    }
}

// MARK: - Previews

#Preview("Avatar Sizes") {
    VStack(spacing: L2RTheme.Spacing.xl) {
        HStack(spacing: L2RTheme.Spacing.lg) {
            AvatarView(emoji: .bear, size: .small)
            AvatarView(emoji: .bunny, size: .medium)
            AvatarView(emoji: .fox, size: .large)
            AvatarView(emoji: .owl, size: .xlarge)
        }

        Text("Small · Medium · Large · XLarge")
            .font(L2RTheme.Typography.system(size: 14))
            .foregroundStyle(L2RTheme.textSecondary)
    }
    .padding()
    .background(L2RTheme.background)
}

#Preview("All Avatars") {
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80))],
            spacing: L2RTheme.Spacing.md
        ) {
            ForEach(AvatarEmoji.allCases, id: \.self) { emoji in
                VStack(spacing: L2RTheme.Spacing.xs) {
                    AvatarView(emoji: emoji, size: .large)
                    Text(emoji.displayName)
                        .font(L2RTheme.Typography.system(size: 12))
                        .foregroundStyle(L2RTheme.textSecondary)
                }
            }
        }
        .padding()
    }
    .background(L2RTheme.background)
}

#Preview("Selection States") {
    VStack(spacing: L2RTheme.Spacing.xl) {
        HStack(spacing: L2RTheme.Spacing.lg) {
            AvatarView(emoji: .cat, size: .large, isSelected: false)
            AvatarView(emoji: .dog, size: .large, isSelected: true)
        }

        HStack(spacing: L2RTheme.Spacing.lg) {
            AvatarView(emoji: .panda, size: .xlarge, isSelected: false)
            AvatarView(emoji: .lion, size: .xlarge, isSelected: true)
        }
    }
    .padding()
    .background(L2RTheme.background)
}

#Preview("Avatar Selection Grid") {
    @Previewable @State var selected: AvatarEmoji? = .fox

    VStack(spacing: L2RTheme.Spacing.lg) {
        Text("Choose Your Avatar")
            .font(L2RTheme.Typography.playful(size: 24, weight: .bold))
            .foregroundStyle(L2RTheme.textPrimary)

        AvatarSelectionGrid(selectedEmoji: $selected, columns: 4)
            .padding(.horizontal)

        if let emoji = selected {
            Text("Selected: \(emoji.displayName)")
                .font(L2RTheme.Typography.system(size: 16))
                .foregroundStyle(L2RTheme.textSecondary)
        }
    }
    .padding()
    .background(LinearGradient.homeBackground)
}

#Preview("Border Variants") {
    HStack(spacing: L2RTheme.Spacing.lg) {
        AvatarView(emoji: .bear, size: .large, showBorder: true)
        AvatarView(emoji: .fox, size: .large, showBorder: false)
        AvatarView(
            emoji: .owl,
            size: .large,
            showBorder: true,
            borderColor: L2RTheme.Accent.purple
        )
    }
    .padding()
    .background(L2RTheme.background)
}
