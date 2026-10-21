import SwiftUI

/// Shared chrome around every game: painted sky, home button, star counter
/// and Cutisie's magic window. Games only supply their play area and read
/// `GameID` from the environment.
struct GameScaffold<Content: View>: View {
    let game: GameID
    @ViewBuilder let content: () -> Content

    @Environment(AppServices.self) private var services
    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            SkyBackground(tint: game.colors[0], imageName: game.backgroundImage)
            TouchSparkles()

            content()
                .environment(\.currentGame, game)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                HStack(alignment: .top) {
                    BubbleIconButton(systemName: "house.fill", color: game.colors[0]) {
                        services.feedback.play(.whoosh)
                        services.router.goHome()
                    }
                    Spacer()
                    StarJar()
                }
                Spacer()
                if game.showsActor {
                    HStack {
                        CutisieActor(size: m.s(230))
                            .offset(x: -m.s(20), y: m.s(30))
                        Spacer()
                    }
                }
            }
            .padding(m.s(24))
        }
        .toolbar(.hidden, for: .navigationBar)
        .adaptiveMetrics()
        .onAppear {
            services.mascot.react(.hello)
            services.voice.announce(game.introLine)
        }
        .onDisappear { services.voice.stop() }
    }
}

private struct CurrentGameKey: EnvironmentKey {
    static let defaultValue: GameID? = nil
}

extension EnvironmentValues {
    /// The game a view is running inside, set by `GameScaffold`.
    var currentGame: GameID? {
        get { self[CurrentGameKey.self] }
        set { self[CurrentGameKey.self] = newValue }
    }
}
