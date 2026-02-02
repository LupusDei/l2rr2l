import SwiftUI

// MARK: - L2R Theme

/// Theme configuration for L2RR2L - a playful, child-friendly design system.
/// Ported from the web CSS to create consistent styling across platforms.
public enum L2RTheme {

    // MARK: - Primary Colors

    /// Primary brand color (Indigo)
    public static let primary = Color(hex: "#4f46e5")

    // MARK: - Text Colors

    /// Primary text color
    public static let textPrimary = Color(hex: "#333333")

    /// Secondary text color
    public static let textSecondary = Color(hex: "#666666")

    /// Muted text color
    public static let textMuted = Color(hex: "#495057")

    // MARK: - Background Colors

    /// Main background color
    public static let background = Color(hex: "#f8f9fa")

    /// Border color
    public static let border = Color(hex: "#e9ecef")

    /// Input border color
    public static let inputBorder = Color(hex: "#d1d5db")

    // MARK: - Status Colors

    public enum Status {
        /// Success state
        public static let success = Color(hex: "#6bcb77")

        /// Success alternate
        public static let successAlt = Color(hex: "#51cf66")

        /// Warning state
        public static let warning = Color(hex: "#ffd93d")

        /// Warning alternate
        public static let warningAlt = Color(hex: "#ffd43b")

        /// Error state
        public static let error = Color(hex: "#ff6b6b")

        /// Error alternate
        public static let errorAlt = Color(hex: "#ff922b")

        /// Info state
        public static let info = Color(hex: "#4dabf7")
    }

    // MARK: - Accent Colors (Playful palette for kids)

    public enum Accent {
        /// Purple accent
        public static let purple = Color(hex: "#cc5de8")

        /// Teal accent
        public static let teal = Color(hex: "#20c997")

        /// Orange accent
        public static let orange = Color(hex: "#ff922b")

        /// Pink accent
        public static let pink = Color(hex: "#f093fb")

        /// Coral accent
        public static let coral = Color(hex: "#f5576c")
    }

    // MARK: - Logo Colors (Rainbow palette)

    public enum Logo {
        public static let red = Color(hex: "#ff6b6b")
        public static let yellow = Color(hex: "#ffd43b")
        public static let green = Color(hex: "#51cf66")
        public static let blue = Color(hex: "#4dabf7")
        public static let purple = Color(hex: "#cc5de8")
        public static let orange = Color(hex: "#ff922b")

        /// All logo colors in order
        public static let all: [Color] = [red, yellow, green, blue, purple, orange]
    }

    // MARK: - Game Colors

    public enum Game {
        /// Spelling game gradient colors
        public static let spellingStart = Color(hex: "#51cf66")
        public static let spellingEnd = Color(hex: "#20c997")
        public static let spellingShadow = Color(hex: "#12b886")

        /// Memory game gradient colors
        public static let memoryStart = Color(hex: "#667eea")
        public static let memoryEnd = Color(hex: "#764ba2")
        public static let memoryShadow = Color(hex: "#5a4d8a")

        /// Rhyme game gradient colors
        public static let rhymeStart = Color(hex: "#f093fb")
        public static let rhymeEnd = Color(hex: "#f5576c")
        public static let rhymeShadow = Color(hex: "#d63a5a")

        /// Word builder gradient colors
        public static let builderStart = Color(hex: "#f39c12")
        public static let builderEnd = Color(hex: "#d35400")
        public static let builderShadow = Color(hex: "#a04000")

        /// Phonics game gradient colors
        public static let phonicsStart = Color(hex: "#00b4db")
        public static let phonicsEnd = Color(hex: "#0083b0")
        public static let phonicsShadow = Color(hex: "#006080")

        /// Read aloud game gradient colors
        public static let readAloudStart = Color(hex: "#9b59b6")
        public static let readAloudEnd = Color(hex: "#8e44ad")
        public static let readAloudShadow = Color(hex: "#6c3483")
    }

    // MARK: - CTA Button Colors

    public enum CTA {
        public static let gradientStart = Color(hex: "#ff6b6b")
        public static let gradientEnd = Color(hex: "#ff922b")
        public static let shadow = Color(hex: "#e55039")
    }

    // MARK: - Typography

    public enum Typography {
        /// Primary font for playful elements
        public static let playfulFont = "Comic Sans MS"

        /// Fallback font
        public static let fallbackFont = "Chalkboard"

        /// Get playful font with size
        public static func playful(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom(playfulFont, size: size).weight(weight)
        }

        /// System font for regular text
        public static func system(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }

        /// Child-friendly larger sizes
        public enum Size {
            public static let small: CGFloat = 14
            public static let body: CGFloat = 16
            public static let large: CGFloat = 18
            public static let title3: CGFloat = 20
            public static let title2: CGFloat = 24
            public static let title1: CGFloat = 28
            public static let largeTitle: CGFloat = 34
            public static let logo: CGFloat = 56
        }
    }

    // MARK: - Spacing (8-point grid)

    public enum Spacing {
        public static let xxxs: CGFloat = 2
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 40
        public static let huge: CGFloat = 48
    }

    // MARK: - Corner Radius

    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let xlarge: CGFloat = 24
        public static let pill: CGFloat = 50
    }

    // MARK: - Touch Targets (WCAG 2.5.5)

    public enum TouchTarget {
        public static let minimum: CGFloat = 44
        public static let comfortable: CGFloat = 48
        public static let large: CGFloat = 56
        public static let xlarge: CGFloat = 60
    }

    // MARK: - Shadows

    public enum Shadow {
        /// Card shadow
        public static func card() -> some View {
            Color.black.opacity(0.1)
        }

        /// Button depth (3D effect)
        public static let buttonDepth: CGFloat = 6

        /// Elevated button depth
        public static let buttonDepthHover: CGFloat = 8

        /// Pressed button depth
        public static let buttonDepthPressed: CGFloat = 2
    }

    // MARK: - Animation

    public enum Animation {
        public static let fast: Double = 0.15
        public static let normal: Double = 0.2
        public static let slow: Double = 0.3

        /// Bounce animation for playful elements
        public static var bounce: SwiftUI.Animation {
            .spring(response: 0.4, dampingFraction: 0.6)
        }

        /// Pulse animation for CTA buttons
        public static var pulse: SwiftUI.Animation {
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        }

        /// Float animation for decorations
        public static var float: SwiftUI.Animation {
            .easeInOut(duration: 6.0).repeatForever(autoreverses: true)
        }

        /// Twinkle animation for stars
        public static var twinkle: SwiftUI.Animation {
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        }

        /// Wiggle animation for game icons
        public static var wiggle: SwiftUI.Animation {
            .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
        }
    }
}

// MARK: - Gradients

extension LinearGradient {
    /// Home screen background gradient
    public static let homeBackground = LinearGradient(
        colors: [
            Color(hex: "#fff9e6"),
            Color(hex: "#ffe6f0"),
            Color(hex: "#e6f3ff")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Memory game gradient
    public static let memoryGame = LinearGradient(
        colors: [
            L2RTheme.Game.memoryStart,
            L2RTheme.Game.memoryEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Spelling game gradient
    public static let spellingGame = LinearGradient(
        colors: [
            L2RTheme.Game.spellingStart,
            L2RTheme.Game.spellingEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Rhyme game gradient
    public static let rhymeGame = LinearGradient(
        colors: [
            L2RTheme.Game.rhymeStart,
            L2RTheme.Game.rhymeEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Word builder gradient
    public static let wordBuilder = LinearGradient(
        colors: [
            L2RTheme.Game.builderStart,
            L2RTheme.Game.builderEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Phonics game gradient
    public static let phonicsGame = LinearGradient(
        colors: [
            L2RTheme.Game.phonicsStart,
            L2RTheme.Game.phonicsEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Read aloud game gradient
    public static let readAloudGame = LinearGradient(
        colors: [
            L2RTheme.Game.readAloudStart,
            L2RTheme.Game.readAloudEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// CTA button gradient
    public static let ctaButton = LinearGradient(
        colors: [
            L2RTheme.CTA.gradientStart,
            L2RTheme.CTA.gradientEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Environment Key

/// Environment key for accessing the theme
private struct L2RThemeKey: EnvironmentKey {
    static let defaultValue: L2RThemeEnvironment = L2RThemeEnvironment()
}

/// Theme environment values
public struct L2RThemeEnvironment {
    public var usePlayfulFont: Bool = true
    public var reduceAnimations: Bool = false
}

extension EnvironmentValues {
    /// The current L2R theme configuration
    public var l2rTheme: L2RThemeEnvironment {
        get { self[L2RThemeKey.self] }
        set { self[L2RThemeKey.self] = newValue }
    }
}

extension View {
    /// Apply L2R theme configuration
    public func l2rTheme(_ theme: L2RThemeEnvironment) -> some View {
        environment(\.l2rTheme, theme)
    }

    /// Enable or disable playful fonts
    public func usePlayfulFont(_ enabled: Bool) -> some View {
        environment(\.l2rTheme.usePlayfulFont, enabled)
    }
}
