import CoreHaptics
import UIKit

/// Haptics for iPhone. iPads have no Taptic Engine, so on iPad this quietly
/// does nothing and the feel comes from sound and animation (see `Feedback`).
@MainActor
final class Haptics {
    let isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private let light = UIImpactFeedbackGenerator(style: .soft)
    private let heavy = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()
    private let select = UISelectionFeedbackGenerator()

    enum Kind { case tap, pick, drop, success, gentleMiss, celebrate }

    func play(_ kind: Kind) {
        guard isSupported else { return }
        switch kind {
        case .tap: light.impactOccurred(intensity: 0.6)
        case .pick: select.selectionChanged()
        case .drop: heavy.impactOccurred(intensity: 0.8)
        case .success: notify.notificationOccurred(.success)
        case .gentleMiss: light.impactOccurred(intensity: 0.4)
        case .celebrate:
            notify.notificationOccurred(.success)
            Task {
                for _ in 0..<3 {
                    try? await Task.sleep(for: .milliseconds(120))
                    heavy.impactOccurred(intensity: 0.7)
                }
            }
        }
    }
}
