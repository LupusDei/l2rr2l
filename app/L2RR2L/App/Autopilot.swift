import Foundation

#if DEBUG
/// Debug-only player for end-to-end runs (`-autopilot` launch argument):
/// plays the Sparkle Check, then one full session (warm-up, three games,
/// treasure) through the same model calls a child's taps make, at a
/// watchable pace. Every so often it answers wrong first so hints and the
/// struggle rule get exercised. Nothing here ships in release builds.
@MainActor
enum Autopilot {
    static let enabled = CommandLine.arguments.contains("-autopilot")
    /// `-game <id>` with `-autopilot`: play only that game (e.g. readAlong).
    static let soloGame: GameID? = {
        let args = CommandLine.arguments
        guard enabled, let i = args.firstIndex(of: "-game"), i + 1 < args.count else { return nil }
        return GameID(rawValue: args[i + 1])
    }()
    /// Counts answers so every few is deliberately wrong first.
    static var answers = 0
    static var sessionsPlayed = 0

    static var shouldMissThisOne: Bool {
        answers += 1
        return answers % 4 == 0
    }

    /// End of a round: next step of the session, or home.
    static func finishRound(_ services: AppServices) {
        after(4) {
            if services.router.inSession { services.router.advance() } else { services.router.goHome() }
        }
    }

    static func after(_ seconds: Double, _ action: @escaping @MainActor () async -> Void) {
        guard enabled else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            await action()
        }
    }
}
#endif
