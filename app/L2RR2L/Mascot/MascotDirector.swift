import SwiftUI

/// Cutisie's video clips, named to match `art/cutisie/BRIEF.md`.
/// Drop `<rawValue>.mp4` (or .mov, HEVC with alpha works) into `Media/mascot/`.
enum MascotClip: String, CaseIterable {
    case hello, cheer, dance, encourage, think, listen, fly, read, bird

    /// Whether the clip loops while it's the current pose, or plays once and
    /// settles back to idle.
    var loops: Bool { self == .fly || self == .listen || self == .think }

    /// Still image to show before/without video (`idle.png` etc. from the brief).
    var stillName: String {
        switch self {
        case .hello: "wave"
        case .cheer: "cheer"
        case .dance: "proud"
        case .encourage: "idle"
        case .think: "think"
        case .listen: "listen"
        case .fly: "fly"
        case .read: "read"
        case .bird: "bird"
        }
    }

    /// Cutisie doesn't talk; she squeaks. Which clips get a happy squeak.
    var squeaks: Bool { self == .hello || self == .cheer || self == .dance || self == .encourage }

    var videoURL: URL? {
        for ext in ["mp4", "mov", "m4v"] {
            if let url = Bundle.main.url(forResource: rawValue, withExtension: ext, subdirectory: "Media/mascot") {
                return url
            }
        }
        return nil
    }
}

/// Drives what Cutisie is doing. Cutisie never speaks (the Star Voice does
/// all talking); she reacts with clips and little squeaks. Any screen can call
/// `mascot.react(.cheer)` and every `MascotView` on screen responds.
@MainActor
@Observable
final class MascotDirector {
    private(set) var clip: MascotClip? = nil
    /// Bumps on every reaction so views restart a clip even if it's the same one.
    private(set) var playCount = 0

    @ObservationIgnored private let sounds: SoundEffects
    @ObservationIgnored private var settleTask: Task<Void, Never>?

    /// How long a one-shot clip holds before Cutisie settles back to idle
    /// (clips in the brief are 5 s).
    static let oneShotDuration: Duration = .seconds(5)

    init(sounds: SoundEffects) { self.sounds = sounds }

    func react(_ clip: MascotClip) {
        self.clip = clip
        playCount += 1
        if clip.squeaks { sounds.play(.squeak) }
        settleTask?.cancel()
        guard !clip.loops else { return }
        settleTask = Task { [weak self] in
            try? await Task.sleep(for: Self.oneShotDuration)
            guard !Task.isCancelled else { return }
            self?.clip = nil
        }
    }

    func settle() {
        settleTask?.cancel()
        clip = nil
    }
}
