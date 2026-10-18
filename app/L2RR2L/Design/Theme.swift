import SwiftUI

/// Night-sky palette from the Cutisie art brief: deep navy, pastel aurora,
/// candy-bright accents that glow.
enum Theme {
    static let skyTop = Color(red: 0.05, green: 0.06, blue: 0.20)
    static let skyBottom = Color(red: 0.16, green: 0.10, blue: 0.36)
    static let aurora1 = Color(red: 0.55, green: 0.40, blue: 1.00)
    static let aurora2 = Color(red: 0.25, green: 0.85, blue: 0.95)
    static let aurora3 = Color(red: 1.00, green: 0.55, blue: 0.85)

    static let pink = Color(red: 1.00, green: 0.45, blue: 0.75)
    static let gold = Color(red: 1.00, green: 0.82, blue: 0.30)
    static let mint = Color(red: 0.35, green: 0.95, blue: 0.75)
    static let sky = Color(red: 0.35, green: 0.70, blue: 1.00)
    static let lilac = Color(red: 0.70, green: 0.55, blue: 1.00)
    static let peach = Color(red: 1.00, green: 0.65, blue: 0.45)

    static let confetti: [Color] = [pink, gold, mint, sky, lilac, peach, .white]

    static let cardCorner: CGFloat = 36
}

extension Font {
    /// Big friendly rounded type. Kids' reading text should use `.reading`.
    static func playful(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Letters and words the child reads: clear, single-storey-ish, generous.
    static func reading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

/// Adapts sizes for iPad vs iPhone without sprinkling checks everywhere.
struct Metrics {
    let isCompact: Bool
    var scale: CGFloat { isCompact ? 0.7 : 1 }
    func s(_ value: CGFloat) -> CGFloat { value * scale }
}

private struct MetricsKey: EnvironmentKey {
    static let defaultValue = Metrics(isCompact: false)
}

extension EnvironmentValues {
    var metrics: Metrics {
        get { self[MetricsKey.self] }
        set { self[MetricsKey.self] = newValue }
    }
}

/// Reads the size class and publishes `Metrics` to everything below.
struct AdaptiveMetrics: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    func body(content: Content) -> some View {
        content.environment(\.metrics, Metrics(isCompact: hSize == .compact || vSize == .compact))
    }
}

extension View {
    func adaptiveMetrics() -> some View { modifier(AdaptiveMetrics()) }

    /// Soft neon glow used on cards, tiles and the mascot window.
    func glow(_ color: Color, radius: CGFloat = 18) -> some View {
        shadow(color: color.opacity(0.65), radius: radius)
            .shadow(color: color.opacity(0.35), radius: radius * 2)
    }
}
