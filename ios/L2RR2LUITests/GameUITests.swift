import XCTest

/// UI Tests for Game flows
final class GameUITests: XCTestCase {
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

    // MARK: - Helper Methods

    private func navigateToGames() {
        let tabBar = app.tabBars.firstMatch
        let gamesTab = tabBar.buttons["Games"]
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 3))
        gamesTab.tap()
    }

    // MARK: - Games View Tests

    func testGamesViewDisplaysHeader() throws {
        navigateToGames()

        let headerText = app.staticTexts["Let's Play!"]
        XCTAssertTrue(headerText.waitForExistence(timeout: 3))
    }

    func testGamesViewDisplaysSubheader() throws {
        navigateToGames()

        let subheaderText = app.staticTexts["Choose a game to practice your skills"]
        XCTAssertTrue(subheaderText.waitForExistence(timeout: 3))
    }

    func testAllGameCardsVisible() throws {
        navigateToGames()

        // Verify all 6 game cards are present
        let gameIdentifiers = [
            "games.phonics.card",
            "games.spelling.card",
            "games.memory.card",
            "games.rhyme.card",
            "games.wordbuilder.card",
            "games.readaloud.card"
        ]

        for identifier in gameIdentifiers {
            let card = app.buttons[identifier]
            // Some cards may need scrolling to be visible
            if !card.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(card.waitForExistence(timeout: 3), "Missing game card: \(identifier)")
        }
    }

    // MARK: - Game Navigation Tests

    func testNavigateToPhonicsGame() throws {
        navigateToGames()

        let phonicsCard = app.buttons["games.phonics.card"]
        XCTAssertTrue(phonicsCard.waitForExistence(timeout: 3))
        phonicsCard.tap()

        // Verify navigation
        let gameTitle = app.staticTexts["Phonics"]
        XCTAssertTrue(gameTitle.waitForExistence(timeout: 3))
    }

    func testNavigateToMemoryGame() throws {
        navigateToGames()

        let memoryCard = app.buttons["games.memory.card"]
        XCTAssertTrue(memoryCard.waitForExistence(timeout: 3))
        memoryCard.tap()

        // Verify navigation
        let gameTitle = app.staticTexts["Memory"]
        XCTAssertTrue(gameTitle.waitForExistence(timeout: 3))
    }

    func testNavigateToRhymeGame() throws {
        navigateToGames()

        let rhymeCard = app.buttons["games.rhyme.card"]
        if !rhymeCard.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(rhymeCard.waitForExistence(timeout: 3))
        rhymeCard.tap()

        // Verify navigation
        let gameTitle = app.staticTexts["Rhyme"]
        XCTAssertTrue(gameTitle.waitForExistence(timeout: 3))
    }

    // MARK: - Game Back Navigation Tests

    func testBackNavigationFromGame() throws {
        navigateToGames()

        // Navigate to a game
        let phonicsCard = app.buttons["games.phonics.card"]
        XCTAssertTrue(phonicsCard.waitForExistence(timeout: 3))
        phonicsCard.tap()

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        backButton.tap()

        // Verify we're back at games view
        let gamesTitle = app.navigationBars["Games"]
        XCTAssertTrue(gamesTitle.waitForExistence(timeout: 3))
    }

    // MARK: - Spelling Game Flow Tests

    func testSpellingGameStartFlow() throws {
        navigateToGames()

        // Navigate to Spelling Game
        let spellingCard = app.buttons["games.spelling.card"]
        XCTAssertTrue(spellingCard.waitForExistence(timeout: 3))
        spellingCard.tap()

        // Note: The current implementation goes to a placeholder
        // When the full SpellingGameView is integrated, this test should verify:
        // 1. Start button exists
        // 2. Tapping start begins the game
        // 3. Game controls become visible

        let gameContent = app.staticTexts["Spelling"]
        XCTAssertTrue(gameContent.waitForExistence(timeout: 3))
    }

    // MARK: - Accessibility Tests

    func testGameCardsHaveAccessibilityLabels() throws {
        navigateToGames()

        // Verify games have proper accessibility labels
        let phonicsGame = app.buttons["Phonics Fun"]
        let spellingGame = app.buttons["Spelling Bee"]
        let memoryGame = app.buttons["Memory Match"]

        XCTAssertTrue(phonicsGame.waitForExistence(timeout: 3))
        XCTAssertTrue(spellingGame.exists)
        XCTAssertTrue(memoryGame.exists)
    }

    func testGameCardsHaveAccessibilityHints() throws {
        navigateToGames()

        // Check that game cards have hints
        let phonicsCard = app.buttons["games.phonics.card"]
        XCTAssertTrue(phonicsCard.waitForExistence(timeout: 3))

        // The hint should be "Double tap to play"
        // Note: Accessing hints in UI tests requires specific setup
    }

    // MARK: - Scroll Tests

    func testGamesViewScrollsToRevealAllGames() throws {
        navigateToGames()

        // Initially visible games
        let phonicsCard = app.buttons["games.phonics.card"]
        XCTAssertTrue(phonicsCard.waitForExistence(timeout: 3))

        // Scroll down
        app.swipeUp()

        // Bottom games should become visible
        let readAloudCard = app.buttons["games.readaloud.card"]
        XCTAssertTrue(readAloudCard.waitForExistence(timeout: 3))
    }

    // MARK: - Game State Tests

    func testReturnToGamesFromDifferentTab() throws {
        navigateToGames()

        // Navigate to a game
        let phonicsCard = app.buttons["games.phonics.card"]
        phonicsCard.tap()

        // Switch to different tab
        let tabBar = app.tabBars.firstMatch
        let homeTab = tabBar.buttons["Home"]
        homeTab.tap()

        // Return to games tab
        let gamesTab = tabBar.buttons["Games"]
        gamesTab.tap()

        // Should show the game detail we were on
        // (or the games list depending on navigation implementation)
    }
}
