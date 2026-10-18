import SwiftUI

/// Fires full-screen celebration effects from anywhere. `CelebrationOverlay`
/// (mounted once in `RootView`) draws them above everything.
@MainActor
@Observable
final class CelebrationCenter {
    enum Kind: Equatable {
        /// Small burst for a right answer.
        case sparkle
        /// Big multi-burst for finishing a round or a milestone.
        case fireworks
        /// A new sticker floats in.
        case sticker(Sticker)
    }

    struct Burst: Identifiable {
        let id = UUID()
        let kind: Kind
        let start = Date()
    }

    private(set) var bursts: [Burst] = []

    func fire(_ kind: Kind) {
        let burst = Burst(kind: kind)
        bursts.append(burst)
        Task {
            try? await Task.sleep(for: .seconds(kind.duration))
            bursts.removeAll { $0.id == burst.id }
        }
    }
}

extension CelebrationCenter.Kind {
    var duration: Double {
        switch self {
        case .sparkle: 1.6
        case .fireworks: 3.2
        case .sticker: 3.0
        }
    }
}
