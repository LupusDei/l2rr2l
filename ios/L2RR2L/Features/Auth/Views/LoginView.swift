import SwiftUI

/// Login screen with email/password form, child-friendly design.
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: L2RTheme.Spacing.xl) {
                // Logo
                logoSection

                // Form
                formSection

                // Login button
                loginButton

                // Links
                linksSection
            }
            .padding(.horizontal, L2RTheme.Spacing.xl)
            .padding(.vertical, L2RTheme.Spacing.xxl)
        }
        .background(L2RTheme.background)
        .onAppear {
            focusedField = .email
        }
        .onSubmit {
            handleSubmit()
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            // Rainbow logo text
            HStack(spacing: 4) {
                ForEach(Array("L2RR2L".enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.logo, weight: .bold))
                        .foregroundStyle(L2RTheme.Logo.all[index % L2RTheme.Logo.all.count])
                        .playfulTextShadow()
                }
            }
            .bouncing()

            Text("Welcome Back!")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title2, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)
        }
        .padding(.bottom, L2RTheme.Spacing.lg)
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            // Email field
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
                Text("Email")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)

                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(L2RTextFieldStyle(hasError: viewModel.emailError != nil))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Auth.emailTextField)
                    .onChange(of: viewModel.email) { _, _ in
                        viewModel.validateEmail()
                    }

                if let error = viewModel.emailError {
                    errorText(error)
                }
            }

            // Password field
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
                Text("Password")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)

                SecureField("Enter your password", text: $viewModel.password)
                    .textFieldStyle(L2RTextFieldStyle(hasError: viewModel.passwordError != nil))
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Auth.passwordTextField)
                    .onChange(of: viewModel.password) { _, _ in
                        viewModel.validatePassword()
                    }

                if let error = viewModel.passwordError {
                    errorText(error)
                }
            }

            // Form-level error
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(L2RTheme.Status.error)
                    Text(error)
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
                        .foregroundStyle(L2RTheme.Status.error)
                }
                .padding(L2RTheme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(L2RTheme.Status.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.small))
            }
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            Task {
                await viewModel.login()
            }
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(viewModel.isLoading ? "Logging in..." : "Log In")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: L2RTheme.TouchTarget.large)
            .background(
                LinearGradient.ctaButton
                    .opacity(viewModel.canSubmit ? 1.0 : 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            .shadow(
                color: L2RTheme.CTA.shadow.opacity(viewModel.canSubmit ? 0.4 : 0.2),
                radius: 4,
                x: 0,
                y: L2RTheme.Shadow.buttonDepth
            )
        }
        .disabled(!viewModel.canSubmit)
        .accessibilityIdentifier(AccessibilityIdentifiers.Auth.loginButton)
        .padding(.top, L2RTheme.Spacing.sm)
    }

    // MARK: - Links Section

    private var linksSection: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            // Forgot password
            Button {
                // TODO: Navigate to forgot password
            } label: {
                Text("Forgot your password?")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                    .foregroundStyle(L2RTheme.primary)
            }
            .touchTarget()

            // Register link
            HStack(spacing: L2RTheme.Spacing.xxs) {
                Text("Don't have an account?")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                    .foregroundStyle(L2RTheme.textSecondary)

                Button {
                    // TODO: Navigate to registration
                } label: {
                    Text("Sign Up")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                        .foregroundStyle(L2RTheme.primary)
                }
            }
            .touchTarget()
        }
        .padding(.top, L2RTheme.Spacing.sm)
    }

    // MARK: - Helpers

    private func errorText(_ text: String) -> some View {
        Text(text)
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.small))
            .foregroundStyle(L2RTheme.Status.error)
    }

    private func handleSubmit() {
        switch focusedField {
        case .email:
            focusedField = .password
        case .password:
            Task {
                await viewModel.login()
            }
        case .none:
            break
        }
    }
}

// MARK: - Text Field Style

/// Custom text field style matching the L2R design system
struct L2RTextFieldStyle: TextFieldStyle {
    let hasError: Bool

    init(hasError: Bool = false) {
        self.hasError = hasError
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
            .padding(L2RTheme.Spacing.md)
            .frame(minHeight: L2RTheme.TouchTarget.comfortable)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .stroke(
                        hasError ? L2RTheme.Status.error : L2RTheme.inputBorder,
                        lineWidth: hasError ? 2 : 1
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}
