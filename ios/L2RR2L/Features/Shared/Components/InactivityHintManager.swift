import SwiftUI

/// Monitors user inactivity and triggers mascot hints.
///
/// After `AnimationConfig.Inactivity.waveTrigger` seconds of no interaction,
/// the mascot waves. After `hintTrigger` seconds, it shows a contextual hint.
/// Call `resetTimer()` on every user interaction to restart the countdown.
@MainActor
@Observable
final class InactivityHintManager {

    // MARK: - Observable State

    /// Set to true after waveTrigger seconds of inactivity.
    private(set) var shouldWave = false

    /// Set to true after hintTrigger seconds of inactivity.
    private(set) var shouldHint = false

    /// The contextual hint message to show (set by each game).
    private(set) var hintMessage: String = ""

    // MARK: - Private

    nonisolated(unsafe) private var waveTask: Task<Void, Never>?
    nonisolated(unsafe) private var hintTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        startTimers()
    }

    deinit {
        waveTask?.cancel()
        hintTask?.cancel()
    }

    // MARK: - Public API

    /// Call on any user interaction (tap, drag, button press).
    func resetTimer() {
        guard AnimationConfig.Inactivity.resetOnInteraction else { return }
        shouldWave = false
        shouldHint = false
        startTimers()
    }

    /// Set the contextual hint message for the current game.
    func setHintMessage(_ message: String) {
        hintMessage = message
    }

    // MARK: - Private

    private func startTimers() {
        waveTask?.cancel()
        hintTask?.cancel()

        let waveTrigger = AnimationConfig.Inactivity.waveTrigger
        let hintTrigger = AnimationConfig.Inactivity.hintTrigger

        waveTask = Task {
            try? await Task.sleep(for: .seconds(waveTrigger))
            guard !Task.isCancelled else { return }
            shouldWave = true
        }

        hintTask = Task {
            try? await Task.sleep(for: .seconds(hintTrigger))
            guard !Task.isCancelled else { return }
            shouldHint = true
        }
    }
}
