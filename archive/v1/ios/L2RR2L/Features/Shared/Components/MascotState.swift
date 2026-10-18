import SwiftUI

// MARK: - Mascot Animation State

/// The possible animation states for the mascot character.
enum MascotAnimation: String, CaseIterable {
    case idle          // gentle floating/breathing
    case celebrating   // jump + spin on correct answer
    case encouraging   // supportive nod + thumbs up on incorrect
    case hinting       // wave + pointing gesture when stuck
    case dancing       // exaggerated dance on streak milestones
    case proud         // big proud pose on game completion
}

// MARK: - Mascot State Machine

/// Observable state machine that drives mascot animations and speech bubbles.
/// Triggers animations with auto-return to idle after each completes.
@MainActor
@Observable
final class MascotState {

    // MARK: - Published State

    private(set) var currentAnimation: MascotAnimation = .idle
    private(set) var speechBubbleText: String?

    // MARK: - Private

    nonisolated(unsafe) private var returnTask: Task<Void, Never>?

    // MARK: - Animation Durations

    private var duration: TimeInterval {
        switch currentAnimation {
        case .idle:         return 0
        case .celebrating:  return 2.0
        case .encouraging:  return 2.5
        case .hinting:      return 3.0
        case .dancing:      return 3.0
        case .proud:        return 3.5
        }
    }

    // MARK: - Randomized Messages

    private static let celebratingMessages = [
        "Yay!", "Amazing!", "You rock!", "Super star!",
        "Wow!", "Brilliant!", "High five!", "You got it!"
    ]

    private static let encouragingMessages = [
        "You can do it!", "Try again!", "Almost!", "So close!",
        "Keep going!", "You're learning!", "No worries!", "Let's try!"
    ]

    private static let dancingMessages = [
        "On fire!", "Unstoppable!", "Streak!", "Look at you go!",
        "Reading champ!", "So fast!", "Incredible!", "Keep it up!"
    ]

    private static let proudMessages = [
        "You did it!", "All done!", "Champion!", "So proud!",
        "Superstar!", "Way to go!", "Reading hero!", "You're amazing!"
    ]

    // MARK: - Actions

    func celebrate() {
        transition(to: .celebrating, message: Self.celebratingMessages.randomElement())
    }

    func encourage() {
        transition(to: .encouraging, message: Self.encouragingMessages.randomElement())
    }

    func wave() {
        transition(to: .hinting, message: nil)
    }

    func hint(message: String) {
        transition(to: .hinting, message: message)
    }

    func dance() {
        transition(to: .dancing, message: Self.dancingMessages.randomElement())
    }

    func proud() {
        transition(to: .proud, message: Self.proudMessages.randomElement())
    }

    func proud(message: String) {
        transition(to: .proud, message: message)
    }

    // MARK: - Internal

    deinit {
        returnTask?.cancel()
    }

    private func transition(to animation: MascotAnimation, message: String?) {
        returnTask?.cancel()
        currentAnimation = animation
        speechBubbleText = message

        let delay = duration
        returnTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            currentAnimation = .idle
            speechBubbleText = nil
        }
    }
}
