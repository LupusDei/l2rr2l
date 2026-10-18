import SwiftUI

struct RootView: View {
    @Environment(Router.self) private var router
    @Namespace private var zoom

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .game(let game):
                        GameScaffold(game: game) { game.makeView() }
                            .navigationTransition(.zoom(sourceID: game, in: zoom))
                    case .stickerBook:
                        StickerBookView()
                            .navigationTransition(.zoom(sourceID: "stars", in: zoom))
                    case .sparkleCheck:
                        CheckView(kind: .sparkleCheck)
                            .navigationTransition(.zoom(sourceID: "special", in: zoom))
                    case .skyTrial(let stage):
                        CheckView(kind: .skyTrial(stage: stage))
                            .navigationTransition(.zoom(sourceID: "special", in: zoom))
                    case .treasure(let fromSession):
                        TreasureView(fromSession: fromSession)
                    }
                }
        }
        .environment(\.zoomNamespace, zoom)
        .overlay { CelebrationOverlay().allowsHitTesting(false) }
        .overlay { StarVoiceCaption().allowsHitTesting(false) }
        .overlay(alignment: .top) {
            StarVoiceBeacon(size: 40).allowsHitTesting(false).offset(y: -10)
        }
        .adaptiveMetrics()
    }
}

private struct ZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    /// Namespace for the zoom transitions from home into games.
    var zoomNamespace: Namespace.ID? {
        get { self[ZoomNamespaceKey.self] }
        set { self[ZoomNamespaceKey.self] = newValue }
    }
}

extension View {
    /// Marks a view as the place a zoom transition grows out of.
    @ViewBuilder
    func zoomSource(_ id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace { matchedTransitionSource(id: id, in: namespace) } else { self }
    }
}

#Preview {
    RootView().withServices(.preview())
}
