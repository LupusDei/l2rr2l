import SwiftUI

/// Animated app logo with rainbow letters that animate in on appear.
///
/// Features:
/// - Individual letter animation with staggered appearance
/// - Letters slide in alternating from top/bottom
/// - Colorful rainbow letters
/// - Subtle continuous float animation after settling
/// - Optional tap interaction for playful bounce
struct L2RLogoView: View {
    @State private var lettersVisible: [Bool] = Array(repeating: false, count: 6)
    @State private var isFloating = false
    @State private var tappedIndex: Int? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let logoText = Array("L2RR2L")

    /// Whether to show the tagline below the logo
    var showTagline: Bool = true

    /// Optional tap callback when the logo is tapped
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.xs) {
            // Rainbow logo text
            HStack(spacing: 4) {
                ForEach(Array(logoText.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.logo, weight: .bold))
                        .foregroundStyle(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count])
                        .playfulTextShadow()
                        .scaleEffect(letterScale(for: index))
                        .opacity(lettersVisible[index] ? 1.0 : 0.0)
                        .offset(y: letterOffset(for: index))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1),
                            value: lettersVisible[index]
                        )
                        .animation(
                            reduceMotion ? nil : L2RTheme.Animation.float.delay(Double(index) * 0.15),
                            value: isFloating
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: tappedIndex)
                        .onTapGesture {
                            handleLetterTap(index: index)
                        }
                }
            }
            .onTapGesture {
                onTap?()
            }

            // Tagline
            if showTagline {
                Text("Learn to Read")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .medium))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .opacity(lettersVisible.last == true ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.3).delay(0.7), value: lettersVisible.last)
            }
        }
        .onAppear {
            animateLetters()
        }
    }

    // MARK: - Letter Animation Helpers

    /// Calculate the scale for a letter, handling tap bounce
    private func letterScale(for index: Int) -> CGFloat {
        if !lettersVisible[index] {
            return 0.0
        }
        if tappedIndex == index {
            return 1.2
        }
        return 1.0
    }

    /// Calculate the Y offset for a letter based on animation state
    /// Even indices slide from top, odd indices slide from bottom
    private func letterOffset(for index: Int) -> CGFloat {
        if !lettersVisible[index] {
            // Alternating entry direction: even from top (-), odd from bottom (+)
            return index.isMultiple(of: 2) ? -50 : 50
        }

        // Subtle floating animation after settled
        if isFloating && !reduceMotion {
            // Stagger the float offset for wave effect
            let phase = index.isMultiple(of: 2) ? 1.0 : -1.0
            return phase * 3
        }

        return 0
    }

    /// Handle tap on individual letter
    private func handleLetterTap(index: Int) {
        guard !reduceMotion else { return }

        tappedIndex = index

        // Reset after bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            tappedIndex = nil
        }
    }

    private func animateLetters() {
        for index in logoText.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                lettersVisible[index] = true
            }
        }

        // Start floating animation after all letters have appeared
        guard !reduceMotion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isFloating = true
        }
    }
}

#Preview("With Tagline") {
    ZStack {
        LinearGradient.homeBackground
            .ignoresSafeArea()
        L2RLogoView()
    }
}

#Preview("Without Tagline") {
    ZStack {
        LinearGradient.homeBackground
            .ignoresSafeArea()
        L2RLogoView(showTagline: false)
    }
}

#Preview("With Tap Action") {
    ZStack {
        LinearGradient.homeBackground
            .ignoresSafeArea()
        L2RLogoView {
            print("Logo tapped!")
        }
    }
}
