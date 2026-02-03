import Foundation

/// Centralized accessibility identifiers for UI testing.
/// Use these to ensure consistency between app views and UI tests.
enum AccessibilityIdentifiers {
    // MARK: - Home Screen
    enum Home {
        static let settingsButton = "home.settings.button"
        static let welcomeMessage = "home.welcome.message"
        static let continueLearningButton = "home.continue.button"
        static let gameGrid = "home.game.grid"
    }

    // MARK: - Authentication
    enum Auth {
        static let emailTextField = "auth.email.textfield"
        static let passwordTextField = "auth.password.textfield"
        static let loginButton = "auth.login.button"
        static let forgotPasswordButton = "auth.forgot.button"
        static let signUpButton = "auth.signup.button"
        static let errorMessage = "auth.error.message"
        static let logo = "auth.logo"
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let nameTextField = "onboarding.name.textfield"
        static let nameGreeting = "onboarding.name.greeting"
        static let continueButton = "onboarding.continue.button"
        static let ageSelection = "onboarding.age.selection"
        static let avatarSelection = "onboarding.avatar.selection"
        static let completionView = "onboarding.completion"
    }

    // MARK: - Games
    enum Games {
        static let gridView = "games.grid"
        static let phonicsCard = "games.phonics.card"
        static let spellingCard = "games.spelling.card"
        static let memoryCard = "games.memory.card"
        static let rhymeCard = "games.rhyme.card"
        static let wordBuilderCard = "games.wordbuilder.card"
        static let readAloudCard = "games.readaloud.card"
    }

    // MARK: - Spelling Game
    enum SpellingGame {
        static let startButton = "spelling.start.button"
        static let closeButton = "spelling.close.button"
        static let scoreLabel = "spelling.score.label"
        static let streakLabel = "spelling.streak.label"
        static let hintEmoji = "spelling.hint.emoji"
        static let letterBank = "spelling.letter.bank"
        static let dropZone = "spelling.drop.zone"
        static let shuffleButton = "spelling.shuffle.button"
        static let checkButton = "spelling.check.button"
        static let nextButton = "spelling.next.button"
        static let clearButton = "spelling.clear.button"
        static let playAgainButton = "spelling.playagain.button"
        static let doneButton = "spelling.done.button"
        static let gameComplete = "spelling.game.complete"
    }

    // MARK: - Rhyme Game
    enum RhymeGame {
        static let startButton = "rhyme.start.button"
        static let closeButton = "rhyme.close.button"
        static let scoreLabel = "rhyme.score.label"
        static let streakLabel = "rhyme.streak.label"
        static let roundLabel = "rhyme.round.label"
        static let listenButton = "rhyme.listen.button"
        static let targetWord = "rhyme.target.word"
        static let optionsGrid = "rhyme.options.grid"
        static func optionCard(id: String) -> String {
            "rhyme.option.\(id)"
        }
        static let playAgainButton = "rhyme.playagain.button"
        static let doneButton = "rhyme.done.button"
        static let gameComplete = "rhyme.game.complete"
    }

    // MARK: - Lessons
    enum Lessons {
        static let listView = "lessons.list"
        static let headerSection = "lessons.header"
        static func lessonCard(index: Int) -> String {
            "lessons.card.\(index)"
        }
    }

    // MARK: - Lesson Detail
    enum LessonDetail {
        static let titleLabel = "lesson.detail.title"
        static let startButton = "lesson.detail.start"
    }

    // MARK: - Settings
    enum Settings {
        static let view = "settings.view"
        static let voiceSettings = "settings.voice"
        static let resetOnboarding = "settings.reset.onboarding"
    }

    // MARK: - Tab Bar
    enum TabBar {
        static let homeTab = "tabbar.home"
        static let lessonsTab = "tabbar.lessons"
        static let gamesTab = "tabbar.games"
        static let settingsTab = "tabbar.settings"
    }

    // MARK: - Common
    enum Common {
        static let loadingIndicator = "common.loading"
        static let errorView = "common.error"
        static let backButton = "common.back.button"
    }
}
