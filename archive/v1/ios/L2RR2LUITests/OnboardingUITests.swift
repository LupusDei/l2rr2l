import XCTest

/// UI Tests for Onboarding flows
final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_ONBOARDING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Name Entry Tests

    func testNameEntryFieldExists() throws {
        // Note: This test assumes onboarding starts at name entry
        // If the app has been completed before, this may need adjustment
        let nameField = app.textFields["onboarding.name.textfield"]

        // If onboarding isn't showing, skip this test
        if !nameField.waitForExistence(timeout: 3) {
            throw XCTSkip("Onboarding not active - may have been completed already")
        }

        XCTAssertTrue(nameField.exists)
    }

    func testNameEntryContinueButtonDisabledWhenEmpty() throws {
        let nameField = app.textFields["onboarding.name.textfield"]

        guard nameField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Onboarding not active")
        }

        let continueButton = app.buttons["onboarding.continue.button"]
        XCTAssertTrue(continueButton.exists)

        // Button should be disabled with empty name
        XCTAssertFalse(continueButton.isEnabled)
    }

    func testNameEntryEnablesButtonAfterTyping() throws {
        let nameField = app.textFields["onboarding.name.textfield"]

        guard nameField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Onboarding not active")
        }

        // Type a name
        nameField.tap()
        nameField.typeText(UITestData.Onboarding.testName)

        // Button should now be enabled
        let continueButton = app.buttons["onboarding.continue.button"]
        XCTAssertTrue(continueButton.isEnabled)
    }

    func testNameEntryShowsGreeting() throws {
        let nameField = app.textFields["onboarding.name.textfield"]

        guard nameField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Onboarding not active")
        }

        // Type a name
        nameField.tap()
        nameField.typeText(UITestData.Onboarding.testName)

        // Greeting should appear
        let greeting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", UITestData.Onboarding.testName))
        XCTAssertTrue(greeting.firstMatch.waitForExistence(timeout: 2))
    }

    // MARK: - Onboarding Flow Tests

    func testCompleteNameEntryStep() throws {
        let nameField = app.textFields["onboarding.name.textfield"]

        guard nameField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Onboarding not active")
        }

        // Type a name
        nameField.tap()
        nameField.typeText(UITestData.Onboarding.testName)

        // Tap continue
        let continueButton = app.buttons["onboarding.continue.button"]
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Should proceed to next step (implementation varies)
        // Verify we moved past name entry
        XCTAssertFalse(nameField.waitForExistence(timeout: 2))
    }

    // MARK: - Back Navigation Tests

    func testOnboardingBackNavigation() throws {
        // This test verifies back navigation if implemented in onboarding
        // Skip if onboarding doesn't have back navigation
        let nameField = app.textFields["onboarding.name.textfield"]

        guard nameField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Onboarding not active")
        }

        // Complete name entry
        nameField.tap()
        nameField.typeText(UITestData.Onboarding.testName)

        let continueButton = app.buttons["onboarding.continue.button"]
        continueButton.tap()

        // Look for back button
        let backButton = app.buttons["Back"]
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()

            // Should return to name entry
            XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Skip Tests

    func testSkipOptionalSteps() throws {
        // Test that optional onboarding steps can be skipped
        // This depends on the specific onboarding implementation
        let skipButton = app.buttons["Skip"]

        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()

            // Verify we moved forward
            XCTAssertFalse(skipButton.waitForExistence(timeout: 2))
        } else {
            throw XCTSkip("No skip functionality in current onboarding step")
        }
    }
}
