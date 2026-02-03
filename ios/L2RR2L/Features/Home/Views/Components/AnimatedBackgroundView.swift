import SwiftUI

/// Animated gradient background with floating decorations for the home screen.
struct AnimatedBackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Animated gradient
            LinearGradient.homeBackground
                .hueRotation(.degrees(animateGradient && !reduceMotion ? 10 : 0))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: animateGradient
                )

            // Floating decorations (hidden when reduce motion is enabled)
            if !reduceMotion {
                FloatingDecorationsView()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animateGradient = true
        }
    }
}

/// Floating decorative elements (letters, crayons, stars, numbers, paint splashes)
struct FloatingDecorationsView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            // Scattered floating decorations
            Group {
                // Letters
                FloatingLetter(letter: "A", color: L2RTheme.Logo.red)
                    .position(x: width * 0.1, y: height * 0.15)
                    .floating(amplitude: 12)

                FloatingLetter(letter: "B", color: L2RTheme.Logo.yellow)
                    .position(x: width * 0.85, y: height * 0.2)
                    .floating(amplitude: 18)

                FloatingLetter(letter: "C", color: L2RTheme.Logo.green)
                    .position(x: width * 0.15, y: height * 0.75)
                    .floating(amplitude: 14)

                FloatingLetter(letter: "D", color: L2RTheme.Logo.blue)
                    .position(x: width * 0.9, y: height * 0.65)
                    .floating(amplitude: 16)

                // Numbers
                FloatingNumber(number: "1", color: L2RTheme.Logo.purple)
                    .position(x: width * 0.25, y: height * 0.55)
                    .floating(amplitude: 10)

                FloatingNumber(number: "2", color: L2RTheme.Logo.orange)
                    .position(x: width * 0.7, y: height * 0.8)
                    .floating(amplitude: 14)

                FloatingNumber(number: "3", color: L2RTheme.Logo.green)
                    .position(x: width * 0.6, y: height * 0.25)
                    .floating(amplitude: 12)

                // Stars
                FloatingStar()
                    .position(x: width * 0.2, y: height * 0.35)
                    .twinkling()

                FloatingStar()
                    .position(x: width * 0.8, y: height * 0.4)
                    .twinkling()

                FloatingStar()
                    .position(x: width * 0.5, y: height * 0.1)
                    .twinkling()

                // Crayons
                FloatingCrayon(color: L2RTheme.Logo.purple)
                    .position(x: width * 0.05, y: height * 0.5)
                    .floating(amplitude: 10)
                    .rotationEffect(.degrees(-15))

                FloatingCrayon(color: L2RTheme.Logo.orange)
                    .position(x: width * 0.95, y: height * 0.85)
                    .floating(amplitude: 12)
                    .rotationEffect(.degrees(20))

                // Paint splashes
                PaintSplash(color: L2RTheme.Logo.red)
                    .position(x: width * 0.12, y: height * 0.42)
                    .floating(amplitude: 8)

                PaintSplash(color: L2RTheme.Logo.blue)
                    .position(x: width * 0.88, y: height * 0.52)
                    .floating(amplitude: 10)

                PaintSplash(color: L2RTheme.Logo.yellow)
                    .position(x: width * 0.4, y: height * 0.88)
                    .floating(amplitude: 6)
            }
            .opacity(0.6)
        }
    }
}

/// Single floating letter decoration
struct FloatingLetter: View {
    let letter: String
    let color: Color

    var body: some View {
        Text(letter)
            .font(L2RTheme.Typography.playful(size: 32, weight: .bold))
            .foregroundStyle(color)
            .playfulTextShadow(offset: 2)
    }
}

/// Single floating number decoration
struct FloatingNumber: View {
    let number: String
    let color: Color

    var body: some View {
        Text(number)
            .font(L2RTheme.Typography.playful(size: 28, weight: .bold))
            .foregroundStyle(color)
            .playfulTextShadow(offset: 2)
    }
}

/// Star decoration
struct FloatingStar: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 20))
            .foregroundStyle(L2RTheme.Logo.yellow)
    }
}

/// Crayon decoration
struct FloatingCrayon: View {
    let color: Color

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: 8, height: 40)
            .overlay(
                Capsule()
                    .fill(color.opacity(0.7))
                    .frame(width: 8, height: 10)
                    .offset(y: -15)
            )
    }
}

/// Paint splash decoration
struct PaintSplash: View {
    let color: Color

    var body: some View {
        ZStack {
            // Main splash blob
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)

            // Smaller drip circles
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .offset(x: 10, y: 8)

            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .offset(x: -8, y: 10)

            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .offset(x: 6, y: -10)
        }
    }
}

#Preview {
    AnimatedBackgroundView()
}
