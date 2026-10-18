import SwiftUI

enum Route: Hashable {
    case game(GameID)
    case stickerBook
}

@MainActor
@Observable
final class Router {
    var path: [Route] = []

    func open(_ route: Route) { path.append(route) }
    func goHome() { path.removeAll() }
    func back() { if !path.isEmpty { path.removeLast() } }
}
