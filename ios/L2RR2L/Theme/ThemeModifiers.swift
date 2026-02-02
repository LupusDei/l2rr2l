import SwiftUI

// MARK: - Playful Animation Modifiers

/// Float animation modifier for decorative elements
public struct FloatModifier: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat

    public init(amplitude: CGFloat = 15) {
        self.amplitude = amplitude
    }

    public func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : 0)
            .animation(L2RTheme.Animation.float, value: isFloating)
            .onAppear { isFloating = true }
    }
}

/// Twinkle animation modifier for star decorations
public struct TwinkleModifier: ViewModifier {
    @State private var isTwinkling = false

    public func body(content: Content) -> some View {
        content
            .opacity(isTwinkling ? 1.0 : 0.6)
            .scaleEffect(isTwinkling ? 1.2 : 1.0)
            .animation(L2RTheme.Animation.twinkle, value: isTwinkling)
            .onAppear { isTwinkling = true }
    }
}

/// Wiggle animation modifier for game icons
public struct WiggleModifier: ViewModifier {
    @State private var isWiggling = false

    public func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isWiggling ? 3 : -3))
            .animation(L2RTheme.Animation.wiggle, value: isWiggling)
            .onAppear { isWiggling = true }
    }
}

/// Bounce animation modifier for logo letters
public struct BounceModifier: ViewModifier {
    @State private var isBouncing = false
    let delay: Double

    public init(delay: Double = 0) {
        self.delay = delay
    }

    public func body(content: Content) -> some View {
        content
            .offset(y: isBouncing ? -8 : 0)
            .animation(
                L2RTheme.Animation.bounce.delay(delay),
                value: isBouncing
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        isBouncing = true
                    }
                }
            }
    }
}

/// Pulse animation modifier for CTA buttons
public struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .animation(L2RTheme.Animation.pulse, value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply floating animation
    public func floating(amplitude: CGFloat = 15) -> some View {
        modifier(FloatModifier(amplitude: amplitude))
    }

    /// Apply twinkling animation
    public func twinkling() -> some View {
        modifier(TwinkleModifier())
    }

    /// Apply wiggling animation
    public func wiggling() -> some View {
        modifier(WiggleModifier())
    }

    /// Apply bouncing animation with optional delay
    public func bouncing(delay: Double = 0) -> some View {
        modifier(BounceModifier(delay: delay))
    }

    /// Apply pulsing animation
    public func pulsing() -> some View {
        modifier(PulseModifier())
    }
}

// MARK: - Card Style Modifiers

/// 3D card style with playful shadow
public struct PlayfulCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let borderColor: Color
    let shadowColor: Color

    public init(
        cornerRadius: CGFloat = L2RTheme.CornerRadius.xlarge,
        borderColor: Color = .white,
        shadowColor: Color = .black.opacity(0.2)
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.shadowColor = shadowColor
    }

    public func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 4)
            )
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Apply playful card styling
    public func playfulCard(
        cornerRadius: CGFloat = L2RTheme.CornerRadius.xlarge,
        borderColor: Color = .white,
        shadowColor: Color = .black.opacity(0.2)
    ) -> some View {
        modifier(PlayfulCardModifier(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            shadowColor: shadowColor
        ))
    }
}

// MARK: - Touch Target Modifier

/// Ensures minimum touch target size for accessibility
public struct TouchTargetModifier: ViewModifier {
    let minSize: CGFloat

    public init(minSize: CGFloat = L2RTheme.TouchTarget.minimum) {
        self.minSize = minSize
    }

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
    }
}

extension View {
    /// Ensure minimum touch target size
    public func touchTarget(_ size: CGFloat = L2RTheme.TouchTarget.minimum) -> some View {
        modifier(TouchTargetModifier(minSize: size))
    }
}

// MARK: - Text Shadow Modifier (for playful text)

extension View {
    /// Apply playful text shadow effect
    public func playfulTextShadow(
        color: Color = .black.opacity(0.1),
        offset: CGFloat = 3
    ) -> some View {
        self.shadow(color: color, radius: 0, x: offset, y: offset)
    }
}
