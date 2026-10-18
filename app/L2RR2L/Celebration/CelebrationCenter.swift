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
    /// A full-screen milestone scene playing (learning path section 8).
    var milestoneScene: URL?

    /// Plays `Media/scenes/milestone_NN.mp4` full screen if bundled. Returns false if not.
    @discardableResult
    func playMilestone(_ number: Int) -> Bool {
        guard let url = Bundle.main.url(forResource: String(format: "milestone_%02d", number), withExtension: "mp4",
                                        subdirectory: "Media/scenes") else { return false }
        milestoneScene = url
        return true
    }

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
