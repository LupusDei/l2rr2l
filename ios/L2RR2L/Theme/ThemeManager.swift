import SwiftUI

/// Manages the L2RR2L theme settings with persistent storage
@MainActor
public final class ThemeManager: ObservableObject {
    /// Shared singleton instance
    public static let shared = ThemeManager()

    /// Storage keys
    private enum StorageKey {
        static let usePlayfulFont = "l2r_usePlayfulFont"
        static let reduceAnimations = "l2r_reduceAnimations"
    }

    /// Whether to use playful fonts (Comic Sans style)
    @Published public var usePlayfulFont: Bool {
        didSet {
            UserDefaults.standard.set(usePlayfulFont, forKey: StorageKey.usePlayfulFont)
        }
    }

    /// Whether to reduce animations for accessibility
    @Published public var reduceAnimations: Bool {
        didSet {
            UserDefaults.standard.set(reduceAnimations, forKey: StorageKey.reduceAnimations)
        }
    }

    private init() {
        // Load saved preferences or use defaults
        self.usePlayfulFont = UserDefaults.standard.object(forKey: StorageKey.usePlayfulFont) as? Bool ?? true
        self.reduceAnimations = UserDefaults.standard.object(forKey: StorageKey.reduceAnimations) as? Bool ?? false
    }

    /// Get the current theme environment
    public var themeEnvironment: L2RThemeEnvironment {
        L2RThemeEnvironment(
            usePlayfulFont: usePlayfulFont,
            reduceAnimations: reduceAnimations
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the current theme from ThemeManager to the view hierarchy
    @MainActor
    public func withThemeManager(_ themeManager: ThemeManager = .shared) -> some View {
        self.environment(\.l2rTheme, themeManager.themeEnvironment)
    }
}

// MARK: - Font Helpers

extension View {
    /// Apply playful font styling based on theme settings (fixed size)
    @ViewBuilder
    public func playfulFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(L2RTheme.Typography.playful(size: size, weight: weight))
    }

    /// Apply playful font that scales with Dynamic Type
    /// - Parameters:
    ///   - style: The text style to scale relative to
    ///   - weight: Font weight
    @ViewBuilder
    public func scaledPlayfulFont(
        _ style: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> some View {
        self.font(L2RTheme.Typography.Scaled.playful(relativeTo: style, weight: weight))
    }

    /// Apply child-friendly text styling with Dynamic Type support
    @ViewBuilder
    public func childFriendlyText() -> some View {
        self
            .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
            .foregroundStyle(L2RTheme.textPrimary)
    }

    /// Apply scaled headline text for titles and headers
    @ViewBuilder
    public func scaledHeadline(weight: Font.Weight = .bold) -> some View {
        self
            .font(L2RTheme.Typography.Scaled.system(.headline, weight: weight))
    }

    /// Apply scaled title text
    @ViewBuilder
    public func scaledTitle(_ style: Font.TextStyle = .title2, weight: Font.Weight = .bold) -> some View {
        self
            .font(L2RTheme.Typography.Scaled.system(style, weight: weight))
    }

    /// Apply scaled caption text for secondary information
    @ViewBuilder
    public func scaledCaption(weight: Font.Weight = .regular) -> some View {
        self
            .font(L2RTheme.Typography.Scaled.system(.caption, weight: weight))
            .foregroundStyle(L2RTheme.textSecondary)
    }
}

// MARK: - Button Style Helpers

extension View {
    /// Apply 3D button effect with shadow
    public func buttonDepthEffect(
        shadowColor: Color,
        isPressed: Bool = false
    ) -> some View {
        self.shadow(
            color: shadowColor,
            radius: 0,
            x: 0,
            y: isPressed ? L2RTheme.Shadow.buttonDepthPressed : L2RTheme.Shadow.buttonDepth
        )
    }
}
