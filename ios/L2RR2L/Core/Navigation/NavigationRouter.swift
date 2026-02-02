import SwiftUI

@MainActor
final class NavigationRouter: ObservableObject {
    static let shared = NavigationRouter()

    @Published var selectedTab: Tab = .home
    @Published var homePath = NavigationPath()
    @Published var lessonsPath = NavigationPath()
    @Published var gamesPath = NavigationPath()
    @Published var settingsPath = NavigationPath()

    private init() {}

    // MARK: - Deep Linking

    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == "l2rr2l" else {
            return
        }

        switch components.host {
        case "lesson":
            if let lessonId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                navigateToLesson(id: lessonId)
            }
        case "game":
            if let gameType = components.queryItems?.first(where: { $0.name == "type" })?.value {
                navigateToGame(type: gameType)
            }
        case "settings":
            navigateToSettings()
        case "home":
            navigateToHome()
        default:
            break
        }
    }

    // MARK: - Navigation Methods

    func navigateToHome() {
        selectedTab = .home
        homePath = NavigationPath()
    }

    func navigateToLesson(id: String) {
        selectedTab = .lessons
        lessonsPath = NavigationPath()
        lessonsPath.append(LessonDestination.detail(id: id))
    }

    func navigateToGame(type: String) {
        selectedTab = .games
        gamesPath = NavigationPath()
        if let gameType = GameDestination(rawValue: type) {
            gamesPath.append(gameType)
        }
    }

    func navigateToSettings() {
        selectedTab = .settings
        settingsPath = NavigationPath()
    }

    func popToRoot(tab: Tab? = nil) {
        let targetTab = tab ?? selectedTab
        switch targetTab {
        case .home:
            homePath = NavigationPath()
        case .lessons:
            lessonsPath = NavigationPath()
        case .games:
            gamesPath = NavigationPath()
        case .settings:
            settingsPath = NavigationPath()
        }
    }
}

// MARK: - Tab Definition

enum Tab: String, CaseIterable, Identifiable {
    case home
    case lessons
    case games
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .lessons: return "Lessons"
        case .games: return "Games"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .lessons: return "book.fill"
        case .games: return "gamecontroller.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Navigation Destinations

enum LessonDestination: Hashable {
    case detail(id: String)
    case player(id: String)
}

enum GameDestination: String, Hashable {
    case phonics
    case spelling
    case memory
    case rhyme
    case wordBuilder = "word-builder"
    case readAloud = "read-aloud"
}
