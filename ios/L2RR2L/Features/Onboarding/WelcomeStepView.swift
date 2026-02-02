import SwiftUI

/// Welcome step screen for onboarding - the first introduction to the app
struct WelcomeStepView: View {
    let onGetStarted: () -> Void

    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var floatOffset: CGFloat = 0
    @State private var starScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient.homeBackground
                .ignoresSafeArea()

            // Floating decorative elements
            floatingDecorations

            // Main content
            VStack(spacing: L2RTheme.Spacing.xl) {
                Spacer()

                // Animated logo
                logoSection
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.5)

                // Welcome text
                VStack(spacing: L2RTheme.Spacing.sm) {
                    Text("Welcome to L2RR2L!")
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                        .foregroundStyle(L2RTheme.textPrimary)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)

                    Text("Let's learn to read together!")
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .medium))
                        .foregroundStyle(L2RTheme.textSecondary)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 20)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, L2RTheme.Spacing.xl)

                Spacer()

                // Get Started button
                getStartedButton
                    .opacity(showButton ? 1 : 0)
                    .scaleEffect(showButton ? 1 : 0.8)
                    .padding(.bottom, L2RTheme.Spacing.huge)
            }
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            // Rainbow letters logo
            HStack(spacing: L2RTheme.Spacing.xxs) {
                ForEach(Array("L2RR2L".enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.logo, weight: .bold))
                        .foregroundStyle(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count])
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                        .offset(y: floatOffset * (index % 2 == 0 ? 1 : -1))
                }
            }

            // Animated mascot/book icon
            ZStack {
                Circle()
                    .fill(LinearGradient.ctaButton)
                    .frame(width: 80, height: 80)
                    .shadow(color: L2RTheme.CTA.shadow.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "book.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(floatOffset * 2))
            }
            .offset(y: floatOffset)
        }
    }

    // MARK: - Floating Decorations

    private var floatingDecorations: some View {
        GeometryReader { geometry in
            // Stars scattered around
            ForEach(0..<6, id: \.self) { index in
                starDecoration(index: index, size: geometry.size)
            }

            // Floating circles
            ForEach(0..<4, id: \.self) { index in
                circleDecoration(index: index, size: geometry.size)
            }
        }
    }

    private func starDecoration(index: Int, size: CGSize) -> some View {
        let positions: [(CGFloat, CGFloat)] = [
            (0.1, 0.15), (0.85, 0.12), (0.15, 0.75),
            (0.9, 0.65), (0.5, 0.08), (0.7, 0.85)
        ]
        let starSizes: [CGFloat] = [20, 16, 24, 18, 22, 14]
        let (xRatio, yRatio) = positions[index]

        return Image(systemName: "star.fill")
            .font(.system(size: starSizes[index]))
            .foregroundStyle(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count].opacity(0.6))
            .scaleEffect(starScale)
            .position(x: size.width * xRatio, y: size.height * yRatio)
            .animation(
                L2RTheme.Animation.twinkle.delay(Double(index) * 0.2),
                value: starScale
            )
    }

    private func circleDecoration(index: Int, size: CGSize) -> some View {
        let positions: [(CGFloat, CGFloat)] = [
            (0.2, 0.4), (0.8, 0.3), (0.3, 0.9), (0.75, 0.8)
        ]
        let circleSizes: [CGFloat] = [40, 30, 35, 25]
        let (xRatio, yRatio) = positions[index]

        return Circle()
            .fill(L2RTheme.Logo.all[(index + 2) % L2RTheme.Logo.all.count].opacity(0.15))
            .frame(width: circleSizes[index], height: circleSizes[index])
            .offset(y: floatOffset * (index % 2 == 0 ? 1 : -1) * 0.5)
            .position(x: size.width * xRatio, y: size.height * yRatio)
    }

    // MARK: - Get Started Button

    private var getStartedButton: some View {
        Button(action: onGetStarted) {
            HStack(spacing: L2RTheme.Spacing.sm) {
                Text("Get Started")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: L2RTheme.TouchTarget.xlarge)
            .background(
                ZStack {
                    // Shadow layer for 3D effect
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                        .fill(L2RTheme.CTA.shadow)
                        .offset(y: L2RTheme.Shadow.buttonDepth)

                    // Main button
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                        .fill(LinearGradient.ctaButton)
                }
            )
            .padding(.horizontal, L2RTheme.Spacing.xxl)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Animations

    private func animateIn() {
        // Staggered entrance animations
        withAnimation(L2RTheme.Animation.bounce.delay(0.2)) {
            showLogo = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            showTitle = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            showSubtitle = true
        }

        withAnimation(L2RTheme.Animation.bounce.delay(1.0)) {
            showButton = true
        }

        // Start floating animation
        withAnimation(L2RTheme.Animation.float) {
            floatOffset = 8
        }

        // Start star twinkle
        withAnimation(L2RTheme.Animation.twinkle) {
            starScale = 1.2
        }
    }
}

// MARK: - Bounce Button Style

private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? L2RTheme.Shadow.buttonDepth - 2 : 0)
            .animation(.easeInOut(duration: L2RTheme.Animation.fast), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    WelcomeStepView {
        print("Get Started tapped")
    }
}
