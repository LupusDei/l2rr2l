import SwiftUI

/// Animated app logo with rainbow letters that animate in on appear.
struct L2RLogoView: View {
    @State private var lettersVisible: [Bool] = Array(repeating: false, count: 6)
    private let logoText = Array("L2RR2L")

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.xs) {
            // Rainbow logo text
            HStack(spacing: 4) {
                ForEach(Array(logoText.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.logo, weight: .bold))
                        .foregroundStyle(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count])
                        .playfulTextShadow()
                        .scaleEffect(lettersVisible[index] ? 1.0 : 0.0)
                        .opacity(lettersVisible[index] ? 1.0 : 0.0)
                        .offset(y: lettersVisible[index] ? 0 : -20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1),
                            value: lettersVisible[index]
                        )
                }
            }

            // Tagline
            Text("Learn to Read")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)
                .opacity(lettersVisible.last == true ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.7), value: lettersVisible.last)
        }
        .onAppear {
            animateLetters()
        }
    }

    private func animateLetters() {
        for index in logoText.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                lettersVisible[index] = true
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.homeBackground
            .ignoresSafeArea()
        L2RLogoView()
    }
}
