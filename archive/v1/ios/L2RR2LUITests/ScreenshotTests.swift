//
//  ScreenshotTests.swift
//  L2RR2LUITests
//
//  App Store screenshot automation tests.
//  Captures screenshots for all required App Store sizes.
//

import XCTest

/// Screenshot tests for App Store submission.
/// Run with: fastlane snapshot
/// Or manually: xcodebuild test -scheme L2RR2L -testPlan Screenshots
final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Capture Tests

    /// 1. Home screen with animated background and logo
    func test01_HomeScreen() throws {
        // Wait for home screen to load
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()

        // Wait for animations to settle
        sleep(2)

        snapshot("01_HomeScreen")
    }

    /// 2. Games selection grid
    func test02_GamesGrid() throws {
        // Navigate to Games tab
        let gamesTab = app.tabBars.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 5))
        gamesTab.tap()

        // Wait for content to load
        sleep(1)

        snapshot("02_GamesGrid")
    }

    /// 3. Spelling Game start screen
    func test03_SpellingGameStart() throws {
        // Navigate to Games tab
        let gamesTab = app.tabBars.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 5))
        gamesTab.tap()
        sleep(1)

        // Tap Spelling Bee game card
        let spellingCard = app.buttons["Spelling Bee"]
        if spellingCard.waitForExistence(timeout: 3) {
            spellingCard.tap()
            sleep(1)
            snapshot("03_SpellingGameStart")
        }
    }

    /// 4. Spelling Game in action
    func test04_SpellingGamePlaying() throws {
        // Navigate to Games tab
        let gamesTab = app.tabBars.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 5))
        gamesTab.tap()
        sleep(1)

        // Tap Spelling Bee game card
        let spellingCard = app.buttons["Spelling Bee"]
        if spellingCard.waitForExistence(timeout: 3) {
            spellingCard.tap()
            sleep(1)

            // Tap Start Game button
            let startButton = app.buttons["Start Game"]
            if startButton.waitForExistence(timeout: 3) {
                startButton.tap()
                sleep(1)
                snapshot("04_SpellingGamePlaying")
            }
        }
    }

    /// 5. Memory Game (from games list)
    func test05_MemoryGame() throws {
        // Navigate to Games tab
        let gamesTab = app.tabBars.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 5))
        gamesTab.tap()
        sleep(1)

        // Tap Memory Match game card
        let memoryCard = app.buttons["Memory Match"]
        if memoryCard.waitForExistence(timeout: 3) {
            memoryCard.tap()
            sleep(1)
            snapshot("05_MemoryGame")
        }
    }

    /// 6. Lesson browser
    func test06_LessonBrowser() throws {
        // Navigate to Lessons tab
        let lessonsTab = app.tabBars.buttons["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 5))
        lessonsTab.tap()

        // Wait for content to load
        sleep(1)

        snapshot("06_LessonBrowser")
    }

    /// 7. Settings/Progress screen
    func test07_SettingsProgress() throws {
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Wait for content to load
        sleep(1)

        snapshot("07_Settings")
    }

    // MARK: - Helper Methods

    /// Wait for element and tap
    private func tapElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        guard element.waitForExistence(timeout: timeout) else {
            return false
        }
        element.tap()
        return true
    }

    /// Scroll to element
    private func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement) {
        var attempts = 0
        while !element.isHittable && attempts < 10 {
            scrollView.swipeUp()
            attempts += 1
        }
    }
}
