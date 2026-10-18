import SwiftUI

enum Route: Hashable {
    case game(GameID)
    case stickerBook
    case sparkleCheck
    case skyTrial(Int)
    /// End-of-session treasure: treats for Cutisie, the mystery egg, the collectible.
    case treasure(fromSession: Bool)
}

@MainActor
@Observable
final class Router {
    var path: [Route] = []
    /// Steps left in today's session (learning path section 5).
    private(set) var sessionQueue: [Route] = []

    var inSession: Bool { !sessionQueue.isEmpty }

    func open(_ route: Route) { path.append(route) }
    func goHome() {
        sessionQueue = []
        path.removeAll()
    }
    func back() { if !path.isEmpty { path.removeLast() } }

    /// Today's adventure: blend, build, read alone, then the treasure.
    func startSession() {
        sessionQueue = [.game(.wordMachine), .game(.starCatch), .treasure(fromSession: true)]
        path = [.game(.stretchyBlend)]
    }

    /// Move to the next step of the session.
    func advance() {
        guard !sessionQueue.isEmpty else { goHome(); return }
        path.append(sessionQueue.removeFirst())
    }
}
