import SwiftUI

struct AuthFlowView: View {
    @State private var showLogin = true

    var body: some View {
        NavigationStack {
            if showLogin {
                LoginView()
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                withAnimation {
                                    showLogin = false
                                }
                            } label: {
                                Text("Create Account")
                                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                                    .foregroundStyle(L2RTheme.primary)
                            }
                        }
                    }
            } else {
                RegisterView()
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                withAnimation {
                                    showLogin = true
                                }
                            } label: {
                                Text("Already have an account? Log In")
                                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                                    .foregroundStyle(L2RTheme.primary)
                            }
                        }
                    }
            }
        }
    }
}

struct RegisterView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: L2RTheme.Spacing.xl) {
                logoSection
                formSection
                registerButton
            }
            .padding(.horizontal, L2RTheme.Spacing.xl)
            .padding(.vertical, L2RTheme.Spacing.xxl)
        }
        .background(L2RTheme.background)
    }

    private var logoSection: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            HStack(spacing: 4) {
                ForEach(Array("L2RR2L".enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.logo, weight: .bold))
                        .foregroundStyle(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count])
                }
            }

            Text("Create Your Account")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title2, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)
        }
        .padding(.bottom, L2RTheme.Spacing.lg)
    }

    private var formSection: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            fieldView(title: "Name", text: $name, placeholder: "Your name")
            fieldView(title: "Email", text: $email, placeholder: "your@email.com", keyboardType: .emailAddress)
            secureFieldView(title: "Password", text: $password, placeholder: "Create a password")
            secureFieldView(title: "Confirm Password", text: $confirmPassword, placeholder: "Confirm password")

            if let error = errorMessage {
                Text(error)
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                    .foregroundStyle(L2RTheme.Status.error)
                    .padding(L2RTheme.Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(L2RTheme.Status.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small))
            }
        }
    }

    private func fieldView(title: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
            Text(title)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                .foregroundStyle(L2RTheme.textPrimary)

            TextField(placeholder, text: text)
                .textFieldStyle(L2RTextFieldStyle())
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
        }
    }

    private func secureFieldView(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
            Text(title)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                .foregroundStyle(L2RTheme.textPrimary)

            SecureField(placeholder, text: text)
                .textFieldStyle(L2RTextFieldStyle())
        }
    }

    private var registerButton: some View {
        Button {
            Task {
                await register()
            }
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isLoading ? "Creating Account..." : "Create Account")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: L2RTheme.TouchTarget.large)
            .background(LinearGradient.ctaButton.opacity(canSubmit ? 1.0 : 0.6))
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
        }
        .disabled(!canSubmit)
        .padding(.top, L2RTheme.Spacing.sm)
    }

    private var canSubmit: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword && !isLoading
    }

    private func register() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.register(email: email, password: password, name: name)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    AuthFlowView()
}
