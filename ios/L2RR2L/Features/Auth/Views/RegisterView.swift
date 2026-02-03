import SwiftUI

/// Registration screen with name/email/password form, child-friendly design.
struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @FocusState private var focusedField: Field?

    var onLoginTapped: (() -> Void)?

    enum Field: Hashable {
        case name
        case email
        case password
        case confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: L2RTheme.Spacing.xl) {
                // Logo
                logoSection

                // Form
                formSection

                // Terms checkbox
                termsSection

                // Register button
                registerButton

                // Links
                linksSection
            }
            .padding(.horizontal, L2RTheme.Spacing.xl)
            .padding(.vertical, L2RTheme.Spacing.xxl)
        }
        .background(L2RTheme.background)
        .onAppear {
            focusedField = .name
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

            Text("Create Your Account")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title2, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)
        }
        .padding(.bottom, L2RTheme.Spacing.lg)
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            // Name field
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
                Text("Name")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)

                TextField("Enter your name", text: $viewModel.name)
                    .textFieldStyle(L2RTextFieldStyle(hasError: viewModel.nameError != nil))
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Register.nameTextField)
                    .onChange(of: viewModel.name) { _, _ in
                        viewModel.validateName()
                    }

                if let error = viewModel.nameError {
                    errorText(error)
                }
            }

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
                    .accessibilityIdentifier(AccessibilityIdentifiers.Register.emailTextField)
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

                SecureField("Create a password", text: $viewModel.password)
                    .textFieldStyle(L2RTextFieldStyle(hasError: viewModel.passwordError != nil))
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Register.passwordTextField)
                    .onChange(of: viewModel.password) { _, _ in
                        viewModel.validatePassword()
                    }

                if let error = viewModel.passwordError {
                    errorText(error)
                }
            }

            // Confirm password field
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
                Text("Confirm Password")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(L2RTheme.textPrimary)

                SecureField("Confirm your password", text: $viewModel.confirmPassword)
                    .textFieldStyle(L2RTextFieldStyle(hasError: viewModel.confirmPasswordError != nil))
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.done)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Register.confirmPasswordTextField)
                    .onChange(of: viewModel.confirmPassword) { _, _ in
                        viewModel.validateConfirmPassword()
                    }

                if let error = viewModel.confirmPasswordError {
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
                .accessibilityIdentifier(AccessibilityIdentifiers.Register.errorMessage)
            }
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(alignment: .leading, spacing: L2RTheme.Spacing.xs) {
            Button {
                viewModel.termsAccepted.toggle()
                viewModel.validateTerms()
            } label: {
                HStack(alignment: .top, spacing: L2RTheme.Spacing.sm) {
                    Image(systemName: viewModel.termsAccepted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22))
                        .foregroundStyle(viewModel.termsAccepted ? L2RTheme.primary : L2RTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("I agree to the ")
                            .foregroundStyle(L2RTheme.textPrimary)
                        + Text("Terms of Service")
                            .foregroundStyle(L2RTheme.primary)
                            .underline()
                        + Text(" and ")
                            .foregroundStyle(L2RTheme.textPrimary)
                        + Text("Privacy Policy")
                            .foregroundStyle(L2RTheme.primary)
                            .underline()
                    }
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                    .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Register.termsCheckbox)

            if let error = viewModel.termsError {
                errorText(error)
            }
        }
        .padding(.top, L2RTheme.Spacing.xs)
    }

    // MARK: - Register Button

    private var registerButton: some View {
        Button {
            Task {
                await viewModel.register()
            }
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(viewModel.isLoading ? "Creating Account..." : "Create Account")
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
        .accessibilityIdentifier(AccessibilityIdentifiers.Register.registerButton)
        .padding(.top, L2RTheme.Spacing.sm)
    }

    // MARK: - Links Section

    private var linksSection: some View {
        HStack(spacing: L2RTheme.Spacing.xxs) {
            Text("Already have an account?")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body))
                .foregroundStyle(L2RTheme.textSecondary)

            Button {
                onLoginTapped?()
            } label: {
                Text("Log In")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                    .foregroundStyle(L2RTheme.primary)
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Register.loginLink)
        }
        .touchTarget()
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
        case .name:
            focusedField = .email
        case .email:
            focusedField = .password
        case .password:
            focusedField = .confirmPassword
        case .confirmPassword:
            Task {
                await viewModel.register()
            }
        case .none:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    RegisterView()
}
