import SwiftUI

struct MainTabView: View {
    @ObservedObject var router = NavigationRouter.shared
    @ObservedObject var appState = AppState.shared

    init() {
        // Make tab bar icons larger for young children
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel
        UITabBarItem.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 11, weight: .medium)],
            for: .normal
        )
        // Apply larger symbol rendering
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(L2RTheme.primary)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        _ = symbolConfig // used to configure
    }

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
                .navigationDestination(for: GameType.self) { destination in
                    GameDetailView(gameType: destination)
                }
        }
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var router = NavigationRouter.shared
    @State private var isParentalGateUnlocked = false
    @State private var showParentalGate = false

    var body: some View {
        NavigationStack(path: $router.settingsPath) {
            if isParentalGateUnlocked {
                SettingsView()
            } else {
                ParentalGateView {
                    withAnimation(.easeInOut(duration: L2RTheme.Animation.normal)) {
                        isParentalGateUnlocked = true
                    }
                }
            }
        }
    }
}

// MARK: - Parental Gate

/// Simple math problem gate to prevent accidental child access to Settings.
private struct ParentalGateView: View {
    var onUnlock: () -> Void

    @State private var num1 = Int.random(in: 10...30)
    @State private var num2 = Int.random(in: 10...30)
    @State private var answer = ""
    @State private var showError = false
    @FocusState private var isFocused: Bool

    private var correctAnswer: Int { num1 + num2 }

    var body: some View {
        VStack(spacing: L2RTheme.Spacing.xxl) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(L2RTheme.primary.opacity(0.6))

            Text("Grown-Up Check")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            Text("Please solve this to continue:")
                .font(L2RTheme.Typography.Scaled.system(.callout))
                .foregroundStyle(L2RTheme.textSecondary)

            // Math problem
            Text("\(num1) + \(num2) = ?")
                .font(L2RTheme.Typography.Scaled.system(.title, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)

            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .font(L2RTheme.Typography.Scaled.system(.title2, weight: .medium))
                .multilineTextAlignment(.center)
                .frame(width: 120, height: L2RTheme.TouchTarget.xlarge)
                .background(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .fill(L2RTheme.surface)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                        .stroke(showError ? L2RTheme.Status.error : L2RTheme.inputBorder, lineWidth: 2)
                )
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { checkAnswer() }

            if showError {
                Text("That's not right. Try again!")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                    .foregroundStyle(L2RTheme.Status.error)
            }

            Button {
                checkAnswer()
            } label: {
                Text("Unlock")
                    .font(L2RTheme.Typography.Scaled.system(.body, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 160, height: L2RTheme.TouchTarget.comfortable)
                    .background(L2RTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            }

            Spacer()
        }
        .padding(L2RTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(L2RTheme.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private func checkAnswer() {
        if Int(answer) == correctAnswer {
            showError = false
            onUnlock()
        } else {
            showError = true
            answer = ""
            // Generate a new problem
            num1 = Int.random(in: 10...30)
            num2 = Int.random(in: 10...30)
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
    let gameType: GameType

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
