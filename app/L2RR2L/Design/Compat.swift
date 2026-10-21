import SwiftUI
import UIKit

extension Color {
    /// `mix(with:by:)` on iOS 18; a plain sRGB blend before that (iOS 17 iPads).
    func mixed(with other: Color, by amount: Double) -> Color {
        if #available(iOS 18.0, *) { return mix(with: other, by: amount) }
        var a: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var b: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        UIColor(self).getRed(&a.0, green: &a.1, blue: &a.2, alpha: &a.3)
        UIColor(other).getRed(&b.0, green: &b.1, blue: &b.2, alpha: &b.3)
        let t = CGFloat(min(max(amount, 0), 1))
        return Color(.sRGB, red: a.0 + (b.0 - a.0) * t, green: a.1 + (b.1 - a.1) * t,
                     blue: a.2 + (b.2 - a.2) * t, opacity: a.3 + (b.3 - a.3) * t)
    }
}

extension View {
    /// A symbol that keeps bouncing. Indefinite bounce needs iOS 18; on iOS 17
    /// it pulses instead (a repeating bounce there isn't supported).
    @ViewBuilder
    func repeatingBounce(speed: Double = 1, times: Int? = nil) -> some View {
        let options: SymbolEffectOptions = times.map { .repeat($0) } ?? .repeating
        if #available(iOS 18.0, *) {
            symbolEffect(.bounce, options: options.speed(speed))
        } else {
            symbolEffect(.pulse, options: options.speed(speed))
        }
    }
}
