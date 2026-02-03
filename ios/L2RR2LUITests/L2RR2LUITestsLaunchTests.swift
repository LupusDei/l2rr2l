import XCTest

/// Launch tests with screenshot capture for each UI configuration
final class L2RR2LUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Take a screenshot of the launch screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testHomeScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Wait for home screen to load
        let settingsButton = app.buttons["home.settings.button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))

        // Take screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testGamesScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Games
        let tabBar = app.tabBars.firstMatch
        let gamesTab = tabBar.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 3))
        gamesTab.tap()

        // Wait for games view
        let phonicsCard = app.buttons["games.phonics.card"]
        XCTAssertTrue(phonicsCard.waitForExistence(timeout: 3))

        // Take screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Games Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLessonsScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Lessons
        let tabBar = app.tabBars.firstMatch
        let lessonsTab = tabBar.buttons["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 3))
        lessonsTab.tap()

        // Wait for lessons view
        let lessonCard = app.buttons["lessons.card.0"]
        XCTAssertTrue(lessonCard.waitForExistence(timeout: 3))

        // Take screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Lessons Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSettingsScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Settings
        let tabBar = app.tabBars.firstMatch
        let settingsTab = tabBar.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3))
        settingsTab.tap()

        // Take screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Settings Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDarkModeScreenshot() throws {
        // This test captures the app in dark mode
        // Note: Actual dark mode testing requires specific simulator configuration
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "App Screenshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
