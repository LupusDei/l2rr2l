import XCTest

final class L2RR2LUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    func testAppLaunchesSuccessfully() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    // MARK: - Home Screen Tests

    func testHomeScreenDisplaysSettingsButton() throws {
        let settingsButton = app.buttons["home.settings.button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
    }

    func testHomeScreenDisplaysContinueLearningButton() throws {
        let continueButton = app.buttons["home.continue.button"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
    }

    func testSettingsButtonOpensSettings() throws {
        let settingsButton = app.buttons["home.settings.button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // Settings sheet should appear
        let settingsText = app.staticTexts["Settings"]
        XCTAssertTrue(settingsText.waitForExistence(timeout: 3))
    }

    // MARK: - Tab Navigation Tests

    func testTabBarNavigation() throws {
        // Verify we can navigate to each tab
        let tabBar = app.tabBars.firstMatch

        // Navigate to Lessons tab
        let lessonsTab = tabBar.buttons["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 3))
        lessonsTab.tap()

        // Verify lessons view appears
        let lessonsTitle = app.navigationBars["Lessons"]
        XCTAssertTrue(lessonsTitle.waitForExistence(timeout: 3))

        // Navigate to Games tab
        let gamesTab = tabBar.buttons["Games"]
        gamesTab.tap()

        // Verify games view appears
        let gamesTitle = app.navigationBars["Games"]
        XCTAssertTrue(gamesTitle.waitForExistence(timeout: 3))

        // Navigate to Settings tab
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Navigate back to Home
        let homeTab = tabBar.buttons["Home"]
        homeTab.tap()
    }

    // MARK: - Games View Tests

    func testGamesViewDisplaysAllGames() throws {
        // Navigate to Games tab
        let tabBar = app.tabBars.firstMatch
        let gamesTab = tabBar.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 3))
        gamesTab.tap()

        // Verify game cards are displayed
        let phonicsCard = app.buttons["games.phonics.card"]
        let spellingCard = app.buttons["games.spelling.card"]
        let memoryCard = app.buttons["games.memory.card"]

        XCTAssertTrue(phonicsCard.waitForExistence(timeout: 3))
        XCTAssertTrue(spellingCard.exists)
        XCTAssertTrue(memoryCard.exists)
    }

    func testNavigateToSpellingGame() throws {
        // Navigate to Games tab
        let tabBar = app.tabBars.firstMatch
        let gamesTab = tabBar.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 3))
        gamesTab.tap()

        // Tap on Spelling Game
        let spellingCard = app.buttons["games.spelling.card"]
        XCTAssertTrue(spellingCard.waitForExistence(timeout: 3))
        spellingCard.tap()

        // Verify navigation to game detail
        // Note: Currently this goes to a placeholder view
        let gameContent = app.staticTexts["Spelling"]
        XCTAssertTrue(gameContent.waitForExistence(timeout: 3))
    }

    // MARK: - Lessons View Tests

    func testLessonsViewDisplaysLessonCards() throws {
        // Navigate to Lessons tab
        let tabBar = app.tabBars.firstMatch
        let lessonsTab = tabBar.buttons["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 3))
        lessonsTab.tap()

        // Verify lesson cards are displayed
        let lessonCard0 = app.buttons["lessons.card.0"]
        let lessonCard1 = app.buttons["lessons.card.1"]

        XCTAssertTrue(lessonCard0.waitForExistence(timeout: 3))
        XCTAssertTrue(lessonCard1.exists)
    }

    func testTapLessonCardNavigatesToDetail() throws {
        // Navigate to Lessons tab
        let tabBar = app.tabBars.firstMatch
        let lessonsTab = tabBar.buttons["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 3))
        lessonsTab.tap()

        // Tap on first lesson
        let lessonCard = app.buttons["lessons.card.0"]
        XCTAssertTrue(lessonCard.waitForExistence(timeout: 3))
        lessonCard.tap()

        // Verify navigation to lesson detail
        let lessonDetailText = app.staticTexts["Lesson Details"]
        XCTAssertTrue(lessonDetailText.waitForExistence(timeout: 3))
    }

    // MARK: - Scroll Tests

    func testLessonsViewScrolls() throws {
        // Navigate to Lessons tab
        let tabBar = app.tabBars.firstMatch
        let lessonsTab = tabBar.buttons["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 3))
        lessonsTab.tap()

        // Verify scrolling works
        let lessonCard0 = app.buttons["lessons.card.0"]
        XCTAssertTrue(lessonCard0.waitForExistence(timeout: 3))

        // Scroll down
        app.swipeUp()

        // Should still be able to find some lesson cards
        let lessonCard4 = app.buttons["lessons.card.4"]
        XCTAssertTrue(lessonCard4.waitForExistence(timeout: 3))
    }

    // MARK: - Back Navigation Tests

    func testBackNavigationFromLessonDetail() throws {
        // Navigate to Lessons tab
        let tabBar = app.tabBars.firstMatch
        let lessonsTab = tabBar.buttons["Lessons"]
        XCTAssertTrue(lessonsTab.waitForExistence(timeout: 3))
        lessonsTab.tap()

        // Tap on first lesson
        let lessonCard = app.buttons["lessons.card.0"]
        XCTAssertTrue(lessonCard.waitForExistence(timeout: 3))
        lessonCard.tap()

        // Navigate back
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        backButton.tap()

        // Verify we're back at lessons list
        let lessonsTitle = app.navigationBars["Lessons"]
        XCTAssertTrue(lessonsTitle.waitForExistence(timeout: 3))
    }

    // MARK: - Accessibility Tests

    func testHomeScreenAccessibility() throws {
        // Verify accessibility labels are present
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))

        let continueLearning = app.buttons["Continue Learning"]
        XCTAssertTrue(continueLearning.waitForExistence(timeout: 3))
    }

    func testGamesAccessibilityLabels() throws {
        // Navigate to Games tab
        let tabBar = app.tabBars.firstMatch
        let gamesTab = tabBar.buttons["Games"]
        gamesTab.tap()

        // Verify accessibility labels
        let phonicsGame = app.buttons["Phonics Fun"]
        let spellingGame = app.buttons["Spelling Bee"]
        let memoryGame = app.buttons["Memory Match"]

        XCTAssertTrue(phonicsGame.waitForExistence(timeout: 3))
        XCTAssertTrue(spellingGame.exists)
        XCTAssertTrue(memoryGame.exists)
    }
}
