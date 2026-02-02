import SwiftUI

/// Age selection step of onboarding - asks for the child's age.
struct AgeSelectionView: View {
    @State private var selectedAge: Int?
    @State private var animateSelection: Bool = false

    var onContinue: (Int) -> Void

    private let ages = [4, 5, 6]

    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackgroundView()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Prompt
                promptView
                    .padding(.bottom, L2RTheme.Spacing.xxl)

                // Age buttons
                ageButtonsView
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.bottom, L2RTheme.Spacing.lg)

                // Selection confirmation (appears after age selection)
                if let age = selectedAge {
                    selectionConfirmation(age: age)
                        .padding(.bottom, L2RTheme.Spacing.lg)
                        .transition(.opacity.combined(with: .scale))
                }

                // Continue button
                continueButton
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.bottom, L2RTheme.Spacing.xxl)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, L2RTheme.Spacing.lg)
        }
    }

    // MARK: - Prompt

    private var promptView: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            Text("🎂")
                .font(.system(size: 60))
                .bouncing()

            Text("How old are you?")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title1, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Age Buttons

    private var ageButtonsView: some View {
        HStack(spacing: L2RTheme.Spacing.lg) {
            ForEach(ages, id: \.self) { age in
                AgeButton(
                    age: age,
                    isSelected: selectedAge == age,
                    color: colorForAge(age)
                ) {
                    selectAge(age)
                }
            }
        }
    }

    private func colorForAge(_ age: Int) -> Color {
        switch age {
        case 4: return L2RTheme.Logo.red
        case 5: return L2RTheme.Logo.green
        case 6: return L2RTheme.Logo.blue
        default: return L2RTheme.primary
        }
    }

    // MARK: - Selection Confirmation

    private func selectionConfirmation(age: Int) -> some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            Text("Awesome! You're \(age) years old!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.large, weight: .semibold))
                .foregroundStyle(L2RTheme.Status.success)

            Text("🎉")
                .font(.system(size: L2RTheme.Typography.Size.large))
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            handleContinue()
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                Text("Continue")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: L2RTheme.TouchTarget.xlarge)
            .background(
                Group {
                    if selectedAge != nil {
                        LinearGradient.ctaButton
                    } else {
                        Color.gray.opacity(0.4)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
            .shadow(
                color: selectedAge != nil ? L2RTheme.CTA.shadow.opacity(0.4) : .clear,
                radius: 6,
                x: 0,
                y: L2RTheme.Shadow.buttonDepth
            )
        }
        .disabled(selectedAge == nil)
        .animation(.easeInOut(duration: L2RTheme.Animation.fast), value: selectedAge)
    }

    // MARK: - Actions

    private func selectAge(_ age: Int) {
        withAnimation(L2RTheme.Animation.bounce) {
            selectedAge = age
            animateSelection = true
        }
    }

    private func handleContinue() {
        guard let age = selectedAge else { return }
        onContinue(age)
    }
}

// MARK: - Age Button

private struct AgeButton: View {
    let age: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    @State private var isPressed: Bool = false

    private var buttonSize: CGFloat { 90 }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [.white, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? color.opacity(0.3) : color,
                                lineWidth: isSelected ? 4 : 3
                            )
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.4) : .black.opacity(0.1),
                        radius: isSelected ? 10 : 6,
                        x: 0,
                        y: isPressed ? 2 : (isSelected ? 6 : 4)
                    )

                // Age number
                Text("\(age)")
                    .font(L2RTheme.Typography.playful(size: 44, weight: .bold))
                    .foregroundStyle(isSelected ? .white : color)

                // Selection indicator (checkmark)
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(color)
                        )
                        .offset(x: 30, y: -30)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(AgeButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(L2RTheme.Animation.bounce, value: isSelected)
    }
}

// MARK: - Age Button Style

private struct AgeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    AgeSelectionView { age in
        print("User selected age: \(age)")
    }
}
