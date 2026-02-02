import Foundation
import Combine

/// ViewModel for the login screen, handling email/password authentication.
@MainActor
final class LoginViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var email = ""
    @Published var password = ""
    @Published var emailError: String?
    @Published var passwordError: String?

    // MARK: - Computed Properties

    /// Whether the form is valid and can be submitted
    var isFormValid: Bool {
        isValidEmail(email) && isValidPassword(password)
    }

    /// Whether the login button should be enabled
    var canSubmit: Bool {
        isFormValid && !isLoading
    }

    // MARK: - Validation

    /// Validates email format
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Validates password meets minimum requirements
    private func isValidPassword(_ password: String) -> Bool {
        password.count >= 8
    }

    /// Validates email and sets error message if invalid
    func validateEmail() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            emailError = nil
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }

    /// Validates password and sets error message if invalid
    func validatePassword() {
        if password.isEmpty {
            passwordError = nil
        } else if !isValidPassword(password) {
            passwordError = "Password must be at least 8 characters"
        } else {
            passwordError = nil
        }
    }

    // MARK: - Actions

    /// Attempts to log in with the current credentials
    func login() async {
        validateEmail()
        validatePassword()

        guard emailError == nil, passwordError == nil, isFormValid else {
            if email.isEmpty {
                emailError = "Email is required"
            }
            if password.isEmpty {
                passwordError = "Password is required"
            }
            return
        }

        await performAsyncAction {
            // TODO: Implement actual authentication service call
            // For now, simulate a network delay
            try await Task.sleep(nanoseconds: 1_500_000_000)

            // Placeholder for authentication logic
            // try await authService.login(email: self.email, password: self.password)
        }
    }

    /// Clears all form fields and errors
    func clearForm() {
        email = ""
        password = ""
        emailError = nil
        passwordError = nil
        clearError()
    }
}
