import Foundation
import Combine

/// ViewModel for the registration screen, handling user registration with validation.
@MainActor
final class RegisterViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var termsAccepted = false

    @Published var nameError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var termsError: String?

    // MARK: - Dependencies

    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService = .shared) {
        self.authService = authService
        super.init()
    }

    // MARK: - Computed Properties

    /// Whether the form is valid and can be submitted
    var isFormValid: Bool {
        isValidName(name) &&
        isValidEmail(email) &&
        isValidPassword(password) &&
        passwordsMatch &&
        termsAccepted
    }

    /// Whether the register button should be enabled
    var canSubmit: Bool {
        isFormValid && !isLoading
    }

    /// Whether passwords match
    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    // MARK: - Validation

    private func isValidName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func isValidPassword(_ password: String) -> Bool {
        password.count >= 8
    }

    /// Validates name and sets error message if invalid
    func validateName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty && !name.isEmpty {
            nameError = "Name is required"
        } else {
            nameError = nil
        }
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
        // Re-validate confirm password when password changes
        if !confirmPassword.isEmpty {
            validateConfirmPassword()
        }
    }

    /// Validates confirm password matches password
    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = nil
        } else if password != confirmPassword {
            confirmPasswordError = "Passwords don't match"
        } else {
            confirmPasswordError = nil
        }
    }

    /// Validates terms acceptance
    func validateTerms() {
        if !termsAccepted {
            termsError = "You must accept the terms and conditions"
        } else {
            termsError = nil
        }
    }

    // MARK: - Actions

    /// Attempts to register with the current form data
    func register() async {
        validateName()
        validateEmail()
        validatePassword()
        validateConfirmPassword()
        validateTerms()

        // Check required fields
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Name is required"
        }
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Email is required"
        }
        if password.isEmpty {
            passwordError = "Password is required"
        }
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
        }

        guard nameError == nil,
              emailError == nil,
              passwordError == nil,
              confirmPasswordError == nil,
              termsError == nil,
              isFormValid else {
            return
        }

        await performAsyncAction {
            _ = try await self.authService.register(
                email: self.email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: self.password,
                name: self.name.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    /// Clears all form fields and errors
    func clearForm() {
        name = ""
        email = ""
        password = ""
        confirmPassword = ""
        termsAccepted = false
        nameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        termsError = nil
        clearError()
    }
}
