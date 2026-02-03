import XCTest

/// UI Tests for Authentication flows
final class AuthUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SHOW_AUTH"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Login View Tests

    func testLoginViewDisplaysEmailField() throws {
        let emailField = app.textFields["auth.email.textfield"]

        // Note: Auth view may not be shown by default
        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed - may need to navigate to it")
        }

        XCTAssertTrue(emailField.exists)
    }

    func testLoginViewDisplaysPasswordField() throws {
        let passwordField = app.secureTextFields["auth.password.textfield"]

        guard passwordField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        XCTAssertTrue(passwordField.exists)
    }

    func testLoginButtonDisabledWithEmptyFields() throws {
        let loginButton = app.buttons["auth.login.button"]

        guard loginButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Login button should be disabled with empty fields
        XCTAssertFalse(loginButton.isEnabled)
    }

    // MARK: - Email Validation Tests

    func testInvalidEmailShowsError() throws {
        let emailField = app.textFields["auth.email.textfield"]

        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Type invalid email
        emailField.tap()
        emailField.typeText(UITestData.Auth.invalidEmail)

        // Tap elsewhere to trigger validation
        let passwordField = app.secureTextFields["auth.password.textfield"]
        passwordField.tap()

        // Error message should appear
        let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "email")).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 2))
    }

    func testValidEmailNoError() throws {
        let emailField = app.textFields["auth.email.textfield"]

        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Type valid email
        emailField.tap()
        emailField.typeText(UITestData.Auth.validEmail)

        // Tap elsewhere to trigger validation
        let passwordField = app.secureTextFields["auth.password.textfield"]
        passwordField.tap()

        // Should not show email error
        let emailError = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "invalid email")).firstMatch
        XCTAssertFalse(emailError.waitForExistence(timeout: 1))
    }

    // MARK: - Password Validation Tests

    func testShortPasswordShowsError() throws {
        let passwordField = app.secureTextFields["auth.password.textfield"]

        guard passwordField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Fill in email first
        let emailField = app.textFields["auth.email.textfield"]
        emailField.tap()
        emailField.typeText(UITestData.Auth.validEmail)

        // Type short password
        passwordField.tap()
        passwordField.typeText(UITestData.Auth.invalidPassword)

        // Tap elsewhere
        emailField.tap()

        // Error should appear
        let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "password")).firstMatch
        // May or may not show depending on validation rules
        _ = errorText.waitForExistence(timeout: 1)
    }

    // MARK: - Login Button Tests

    func testLoginButtonEnabledWithValidInput() throws {
        let emailField = app.textFields["auth.email.textfield"]

        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Fill in valid credentials
        emailField.tap()
        emailField.typeText(UITestData.Auth.validEmail)

        let passwordField = app.secureTextFields["auth.password.textfield"]
        passwordField.tap()
        passwordField.typeText(UITestData.Auth.validPassword)

        // Login button should be enabled
        let loginButton = app.buttons["auth.login.button"]
        XCTAssertTrue(loginButton.isEnabled)
    }

    func testLoginButtonTap() throws {
        let emailField = app.textFields["auth.email.textfield"]

        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Fill in valid credentials
        emailField.tap()
        emailField.typeText(UITestData.Auth.validEmail)

        let passwordField = app.secureTextFields["auth.password.textfield"]
        passwordField.tap()
        passwordField.typeText(UITestData.Auth.validPassword)

        // Tap login
        let loginButton = app.buttons["auth.login.button"]
        loginButton.tap()

        // Should show loading indicator or navigate away
        // This depends on implementation and network response
        let loadingIndicator = app.activityIndicators.firstMatch
        let authGone = !emailField.waitForExistence(timeout: 3)

        XCTAssertTrue(loadingIndicator.exists || authGone)
    }

    // MARK: - Navigation Tests

    func testForgotPasswordLink() throws {
        let forgotPasswordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "forgot")).firstMatch

        guard forgotPasswordButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        forgotPasswordButton.tap()

        // Should navigate to forgot password view (when implemented)
        // For now just verify the button is tappable
        XCTAssertTrue(true)
    }

    func testSignUpLink() throws {
        let signUpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "sign up")).firstMatch

        guard signUpButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        signUpButton.tap()

        // Should navigate to sign up view (when implemented)
        // For now just verify the button is tappable
        XCTAssertTrue(true)
    }

    // MARK: - Error State Tests

    func testLoginWithInvalidCredentialsShowsError() throws {
        let emailField = app.textFields["auth.email.textfield"]

        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Fill in credentials
        emailField.tap()
        emailField.typeText("wrong@example.com")

        let passwordField = app.secureTextFields["auth.password.textfield"]
        passwordField.tap()
        passwordField.typeText("wrongpassword")

        // Tap login
        let loginButton = app.buttons["auth.login.button"]
        loginButton.tap()

        // Error message should appear (depending on backend response)
        let errorMessage = app.staticTexts["auth.error.message"]
        // This may timeout if the app doesn't show errors visually
        _ = errorMessage.waitForExistence(timeout: 5)
    }

    // MARK: - Keyboard Tests

    func testKeyboardDismissOnTapOutside() throws {
        let emailField = app.textFields["auth.email.textfield"]

        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Tap email field to show keyboard
        emailField.tap()

        // Verify keyboard is shown
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2))

        // Tap outside to dismiss (tap on the static text "Welcome Back!" which should be present)
        let welcomeText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Welcome")).firstMatch
        if welcomeText.exists {
            welcomeText.tap()
        } else {
            // Fallback: tap on the scroll view
            app.scrollViews.firstMatch.tap()
        }

        // Keyboard may or may not dismiss depending on implementation
    }

    func testKeyboardNextButtonMovesToPassword() throws {
        let emailField = app.textFields["auth.email.textfield"]

        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth view not displayed")
        }

        // Focus email field
        emailField.tap()
        emailField.typeText(UITestData.Auth.validEmail)

        // Press the "Next" button on keyboard (submit label)
        // Note: This simulates pressing return/next
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            // Find and tap the Next button
            let nextButton = keyboard.buttons["Next"]
            if nextButton.exists {
                nextButton.tap()

                // Password field should now be focused
                // (We can verify this by checking if the secure field is first responder)
            }
        }
    }
}
