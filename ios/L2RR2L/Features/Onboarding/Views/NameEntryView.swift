import SwiftUI

/// Name entry step of onboarding - asks for the child's name.
struct NameEntryView: View {
    @State private var name: String = ""
    @State private var showGreeting: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var onContinue: (String) -> Void

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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

                // Name input field
                nameInputField
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.bottom, L2RTheme.Spacing.lg)

                // Greeting message (appears after name entry)
                if showGreeting && isNameValid {
                    greetingMessage
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
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    // MARK: - Prompt

    private var promptView: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            Text("👋")
                .font(.system(size: 60))
                .bouncing()

            Text("What's your name?")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title1, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Name Input Field

    private var nameInputField: some View {
        TextField("Type your name here...", text: $name)
            .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .medium))
            .foregroundStyle(L2RTheme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, L2RTheme.Spacing.lg)
            .padding(.vertical, L2RTheme.Spacing.lg)
            .frame(height: L2RTheme.TouchTarget.xlarge + 16)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .stroke(isTextFieldFocused ? L2RTheme.primary : L2RTheme.inputBorder, lineWidth: isTextFieldFocused ? 3 : 2)
            )
            .focused($isTextFieldFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.nameTextField)
            .onSubmit {
                if isNameValid {
                    handleContinue()
                }
            }
            .onChange(of: name) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !showGreeting {
                    withAnimation(L2RTheme.Animation.bounce) {
                        showGreeting = true
                    }
                } else if trimmed.isEmpty && showGreeting {
                    withAnimation {
                        showGreeting = false
                    }
                }
            }
    }

    // MARK: - Greeting Message

    private var greetingMessage: some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            Text("Nice to meet you, \(name.trimmingCharacters(in: .whitespacesAndNewlines))!")
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
                    if isNameValid {
                        LinearGradient.ctaButton
                    } else {
                        Color.gray.opacity(0.4)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
            .shadow(
                color: isNameValid ? L2RTheme.CTA.shadow.opacity(0.4) : .clear,
                radius: 6,
                x: 0,
                y: L2RTheme.Shadow.buttonDepth
            )
        }
        .disabled(!isNameValid)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.continueButton)
        .animation(.easeInOut(duration: L2RTheme.Animation.fast), value: isNameValid)
    }

    // MARK: - Actions

    private func handleContinue() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        isTextFieldFocused = false
        onContinue(trimmedName)
    }
}

#Preview {
    NameEntryView { name in
        print("User entered name: \(name)")
    }
}
