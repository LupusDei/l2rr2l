import SwiftUI

struct MainTabView: View {
    @ObservedObject var router = NavigationRouter.shared
    @ObservedObject var appState = AppState.shared

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $router.selectedTab) {
                HomeTabView()
                    .tabItem {
                        Label(Tab.home.title, systemImage: Tab.home.icon)
                    }
                    .tag(Tab.home)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TabBar.homeTab)

                LessonsTabView()
                    .tabItem {
                        Label(Tab.lessons.title, systemImage: Tab.lessons.icon)
                    }
                    .tag(Tab.lessons)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TabBar.lessonsTab)

                GamesTabView()
                    .tabItem {
                        Label(Tab.games.title, systemImage: Tab.games.icon)
                    }
                    .tag(Tab.games)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TabBar.gamesTab)

                SettingsTabView()
                    .tabItem {
                        Label(Tab.settings.title, systemImage: Tab.settings.icon)
                    }
                    .tag(Tab.settings)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TabBar.settingsTab)
            }
            .tint(L2RTheme.primary)

            // Offline indicator banner
            if !appState.isNetworkAvailable {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("You're offline — some things may not work")
                        .font(L2RTheme.Typography.Scaled.system(.footnote, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, L2RTheme.Spacing.xs)
                .background(L2RTheme.Status.warning.opacity(0.9))
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: L2RTheme.Animation.normal), value: appState.isNetworkAvailable)
            }
        }
    }
}

// MARK: - Home Tab

struct HomeTabView: View {
    @ObservedObject var router = NavigationRouter.shared

    var body: some View {
        NavigationStack(path: $router.homePath) {
            HomeView()
                .navigationDestination(for: LessonDestination.self) { destination in
                    switch destination {
                    case .detail(let id):
                        LessonDetailContainerView(lessonId: id)
                    case .player(let id):
                        LessonPlayerView(lessonId: id)
                    }
                }
        }
    }
}

// MARK: - Lessons Tab

struct LessonsTabView: View {
    @ObservedObject var router = NavigationRouter.shared

    var body: some View {
        NavigationStack(path: $router.lessonsPath) {
            LessonsView()
                .navigationDestination(for: LessonDestination.self) { destination in
                    switch destination {
                    case .detail(let id):
                        LessonDetailContainerView(lessonId: id)
                    case .player(let id):
                        LessonPlayerView(lessonId: id)
                    }
                }
        }
    }
}

// MARK: - Games Tab

struct GamesTabView: View {
    @ObservedObject var router = NavigationRouter.shared

    var body: some View {
        NavigationStack(path: $router.gamesPath) {
            GamesView()
                .navigationDestination(for: GameDestination.self) { destination in
                    GameDetailView(gameType: destination)
                }
        }
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var router = NavigationRouter.shared

    var body: some View {
        NavigationStack(path: $router.settingsPath) {
            SettingsView()
        }
    }
}

// MARK: - Placeholder Views

struct LessonDetailPlaceholderView: View {
    let lessonId: String

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Image(systemName: "book.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(L2RTheme.primary)

            Text("Lesson Details")
                .font(L2RTheme.Typography.Scaled.system(.title, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            Text("Lesson ID: \(lessonId)")
                .font(L2RTheme.Typography.Scaled.system(.callout))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(L2RTheme.background)
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LessonPlayerPlaceholderView: View {
    let lessonId: String

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(L2RTheme.primary)

            Text("Lesson Player")
                .font(L2RTheme.Typography.Scaled.system(.title, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            Text("Playing: \(lessonId)")
                .font(L2RTheme.Typography.Scaled.system(.callout))
                .foregroundStyle(L2RTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(L2RTheme.background)
        .navigationTitle("Playing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GameDetailView: View {
    let gameType: GameDestination

    var body: some View {
        switch gameType {
        case .spelling:
            SpellingGameView()
                .navigationBarHidden(true)
        case .rhyme:
            RhymeGameView()
                .navigationBarHidden(true)
        case .phonics:
            PhonicsGameView()
                .navigationBarHidden(true)
        case .memory:
            MemoryGameView()
                .navigationBarHidden(true)
        case .wordBuilder:
            WordBuilderView()
                .navigationBarHidden(true)
        case .readAloud:
            ReadAloudGameView()
                .navigationBarHidden(true)
        }
    }
}

#Preview {
    MainTabView()
}
