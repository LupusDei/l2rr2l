import SwiftUI

struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(AppServices.self) private var services
    @Namespace private var zoom

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .game(let game):
                        GameScaffold(game: game) { game.makeView() }
                            .zoomTransition(game, in: zoom)
                    case .stickerBook:
                        StickerBookView()
                            .zoomTransition("stars", in: zoom)
                    case .sparkleCheck:
                        CheckView(kind: .sparkleCheck)
                            .zoomTransition("special", in: zoom)
                    case .skyTrial(let stage):
                        CheckView(kind: .skyTrial(stage: stage))
                            .zoomTransition("special", in: zoom)
                    case .treasure(let fromSession):
                        TreasureView(fromSession: fromSession)
                    case .warmUp(let kind):
                        CheckView(kind: .warmUp(kind))
                    case .newThing(let grapheme):
                        NewThingView(grapheme: grapheme)
                    }
                }
        }
        .environment(\.zoomNamespace, zoom)
        // watches every touch (without blocking any) so Cutisie can follow it
        .background(TouchWatcher(attention: services.attention))
        .overlay { CelebrationOverlay().allowsHitTesting(false) }
        .overlay { WordAliveOverlay() }
        .overlay { StarVoiceCaption().allowsHitTesting(false) }
        .overlay { MilestoneSceneOverlay() }
        .overlay(alignment: .topLeading) {
            // the Star Voice's star sits beside the home button, clear of titles
            StarVoiceBeacon(size: 30).allowsHitTesting(false).offset(x: 80, y: 20)
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
        if #available(iOS 18.0, *), let namespace { matchedTransitionSource(id: id, in: namespace) } else { self }
    }

    /// Grows the pushed screen out of its `zoomSource` (iOS 18); a plain push before that.
    @ViewBuilder
    func zoomTransition(_ id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) { navigationTransition(.zoom(sourceID: id, in: namespace)) } else { self }
    }
}

#Preview {
    RootView().withServices(.preview())
}
