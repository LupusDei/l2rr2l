import SwiftUI

enum Route: Hashable {
    case game(GameID)
    case stickerBook
    case sparkleCheck
    case skyTrial(Int)
    /// End-of-session treasure: treats for Cutisie, the mystery egg, the collectible.
    case treasure(fromSession: Bool)
    case warmUp(WarmUpKind)
    /// "New thing": a story clip introducing one new sound (learning path 5).
    case newThing(String)
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
        sessionStarted = nil
        path.removeAll()
    }
    func back() { if !path.isEmpty { path.removeLast() } }

    /// When today's session started, for the 15-minute cap.
    private(set) var sessionStarted: Date?

    /// Today's adventure (learning path 5): a quick warm-up, blend, build,
    /// read alone, the story moment once she's ready for it, then the treasure.
    func startSession(warmUp: WarmUpKind?, newSound: String? = nil, story: Bool = false) {
        var steps: [Route] = [.game(.stretchyBlend), .game(.wordMachine), .game(.starCatch), .treasure(fromSession: true)]
        if story { steps.insert(.game(.storyMagic), at: 3) }
        if let newSound { steps.insert(.newThing(newSound), at: 0) }
        if let warmUp { steps.insert(.warmUp(warmUp), at: 0) }
        sessionStarted = .now
        path = [steps.removeFirst()]
        sessionQueue = steps
    }

    /// Cut the session short but still end at the celebration.
    func endSessionEarly() {
        guard inSession else { return }
        sessionQueue = []
        path.append(.treasure(fromSession: true))
    }

    /// Move to the next step of the session. After 15 minutes the remaining
    /// games are skipped and she goes straight to the treasure.
    func advance() {
        guard !sessionQueue.isEmpty else { goHome(); return }
        if let started = sessionStarted, Date().timeIntervalSince(started) > AppServices.sessionMinutes * 60 {
            sessionQueue.removeAll { if case .treasure = $0 { false } else { true } }
        }
        path.append(sessionQueue.removeFirst())
    }
}
