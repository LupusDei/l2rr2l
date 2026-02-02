import SwiftUI

// MARK: - Color Hex Initialization

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (e.g., "#FF5733" or "FF5733")
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Convert Color to hex string
    public var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r

        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}

// MARK: - Semantic Color Extensions

extension Color {
    /// L2R primary color
    public static var l2rPrimary: Color { L2RTheme.primary }

    /// L2R text colors
    public static var l2rTextPrimary: Color { L2RTheme.textPrimary }
    public static var l2rTextSecondary: Color { L2RTheme.textSecondary }

    /// L2R background
    public static var l2rBackground: Color { L2RTheme.background }

    /// L2R status colors
    public static var l2rSuccess: Color { L2RTheme.Status.success }
    public static var l2rWarning: Color { L2RTheme.Status.warning }
    public static var l2rError: Color { L2RTheme.Status.error }
    public static var l2rInfo: Color { L2RTheme.Status.info }
}
