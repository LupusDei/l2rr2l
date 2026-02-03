import UIKit

/// Service for providing tactile haptic feedback throughout the app
final class HapticService {
    static let shared = HapticService()

    // MARK: - Feedback Generators

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: - Settings

    private let hapticsEnabledKey = "hapticsEnabled"

    /// Whether haptics are enabled in the app
    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: hapticsEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: hapticsEnabledKey) }
    }

    // MARK: - Initialization

    private init() {
        prepareGenerators()
    }

    // MARK: - Preparation

    /// Prepares all haptic generators for immediate feedback
    /// Call this when entering a view that will use haptics frequently
    func prepare() {
        guard isEnabled else { return }
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }

    private func prepareGenerators() {
        prepare()
    }

    // MARK: - Selection Feedback

    /// Light tap feedback for button presses and selections
    func selection() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    // MARK: - Impact Feedback

    /// Impact feedback with specified style
    /// - Parameter style: The intensity of the impact (.light, .medium, .heavy)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.impactOccurred()
        case .rigid:
            impactHeavy.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }

    /// Light impact for subtle interactions like card flips
    func lightImpact() {
        impact(.light)
    }

    /// Medium impact for significant interactions
    func mediumImpact() {
        impact(.medium)
    }

    /// Heavy impact for major events
    func heavyImpact() {
        impact(.heavy)
    }

    // MARK: - Notification Feedback

    /// Notification feedback with specified type
    /// - Parameter type: The type of notification (.success, .warning, .error)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notification.notificationOccurred(type)
    }

    /// Success feedback for correct answers
    func success() {
        notification(.success)
    }

    /// Warning feedback for hints or near-misses
    func warning() {
        notification(.warning)
    }

    /// Error feedback for incorrect answers
    func error() {
        notification(.error)
    }
}

// MARK: - Convenience Methods for Game Interactions

extension HapticService {
    /// Feedback for tapping a button
    func buttonTap() {
        selection()
    }

    /// Feedback for flipping a card
    func cardFlip() {
        lightImpact()
    }

    /// Feedback for correct answer
    func correctAnswer() {
        success()
    }

    /// Feedback for incorrect answer
    func incorrectAnswer() {
        error()
    }

    /// Feedback for completing a level or game
    func levelComplete() {
        heavyImpact()
    }

    /// Feedback for dragging an item
    func dragStart() {
        lightImpact()
    }

    /// Feedback for dropping an item
    func dropItem() {
        mediumImpact()
    }
}
