import SwiftUI

/// The moments Cutisie reacts to. Each maps to one or more clip takes from the
/// art pack (`art/cutisie/out/manifest.json`); a random take plays so
/// repetition stays fresh. Between moments she loops an idle hover.
enum MascotClip: String, CaseIterable {
    case hello, cheer, streak, dance, encourage, think, listen, read, bird
    case eatTreat, openEgg, goodbye, sleepy, point, magicZap, heartWord
    case catchStar, zoomSlide, carryTile, levelUp, sing

    var takes: [String] {
        switch self {
        case .hello: ["hello_session_1", "hello_session_2", "hello_session_3"]
        case .cheer: ["cheer_small_1", "cheer_small_2", "cheer_small_3", "cheer_small_4"]
        case .streak: ["cheer_streak_1", "cheer_streak_2"]
        case .dance: ["round_done_1", "round_done_2", "round_done_3"]
        case .encourage: ["oops_1", "oops_2", "oops_3"]
        case .think: ["think_1", "think_2"]
        case .listen: ["listen"]
        case .read: ["read_book"]
        case .bird: ["bird_friend"]
        case .eatTreat: ["eat_treat"]
        case .openEgg: ["open_egg"]
        case .goodbye: ["goodbye_session_1", "goodbye_session_2"]
        case .sleepy: ["idle_sleepy", "sleepy"]
        case .point: ["point_down", "point_left"]
        case .magicZap: ["magic_e_zap_1", "magic_e_zap_2"]
        case .heartWord: ["heart_word_1", "heart_word_2"]
        case .catchStar: ["catch_star_1", "catch_star_2"]
        case .zoomSlide: ["zoom_slide_1", "zoom_slide_2"]
        case .carryTile: ["carry_tile"]
        case .levelUp: ["level_up_world"]
        case .sing: ["cheer_sing"]
        }
    }

    static let idleTakes = ["idle_hover_1", "idle_hover_2", "idle_hover_3"]

    /// Pose still (`Media/mascot/poses/<name>.png`) used when clips aren't bundled.
    var poseName: String {
        switch self {
        case .hello: "wave"
        case .cheer, .streak, .catchStar, .sing: "cheer"
        case .dance, .levelUp: "proud"
        case .encourage: "encourage"
        case .think: "think"
        case .listen: "listen"
        case .read: "read"
        case .bird: "bird"
        case .eatTreat: "treat"
        case .openEgg: "egg"
        case .goodbye, .sleepy: "sleepy"
        case .point: "point"
        case .magicZap: "magic"
        case .heartWord: "heart"
        case .zoomSlide: "fly"
        case .carryTile: "hover"
        }
    }

    /// Without video, Cutisie squeaks on the happy moments (clips carry their own sounds).
    var squeaks: Bool { [.hello, .cheer, .streak, .dance, .encourage, .catchStar].contains(self) }

    static func clipURL(_ take: String) -> URL? {
        Bundle.main.url(forResource: take, withExtension: "mov", subdirectory: "Media/mascot/clips")
    }

    static var hasClips: Bool { clipURL(idleTakes[0]) != nil }
}

/// Drives what Cutisie is doing. Cutisie never speaks (the Star Voice does all
/// talking); she reacts with clips, squeaks and giggles. Any screen can call
/// `mascot.react(.cheer)` and every `MascotView` on screen responds, then she
/// settles back into her idle hover when the clip ends.
@MainActor
@Observable
final class MascotDirector {
    private(set) var clip: MascotClip? = nil
    /// The specific take playing for `clip`.
    private(set) var take: String? = nil
    /// Bumps on every reaction so views restart even for the same moment.
    private(set) var playCount = 0
    private(set) var idleTake = MascotClip.idleTakes[0]

    @ObservationIgnored private let sounds: SoundEffects
    @ObservationIgnored private var settleTask: Task<Void, Never>?
    @ObservationIgnored private var lastTake: [MascotClip: String] = [:]

    init(sounds: SoundEffects) { self.sounds = sounds }

    func react(_ clip: MascotClip) {
        let options = clip.takes.filter { $0 != lastTake[clip] }
        let take = (options.isEmpty ? clip.takes : options).randomElement()!
        lastTake[clip] = take
        self.clip = clip
        self.take = take
        playCount += 1
        settleTask?.cancel()
        if MascotClip.clipURL(take) == nil {
            if clip.squeaks { sounds.play(.squeak) }
            // stills: hold the pose briefly, then settle
            let count = playCount
            settleTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2.5))
                self?.finished(count)
            }
        }
    }

    /// Play a specific take from the art pack (unicorn words, new-sound hooks).
    func play(take: String, as moment: MascotClip = .sing) {
        guard MascotClip.clipURL(take) != nil else { react(moment); return }
        settleTask?.cancel()
        clip = moment
        self.take = take
        playCount += 1
    }

    /// Called by the player when a one-shot clip ends.
    func finished(_ count: Int) {
        guard count == playCount, clip != nil else { return }
        clip = nil
        take = nil
        idleTake = MascotClip.idleTakes.randomElement()!
    }

    func settle() {
        settleTask?.cancel()
        finished(playCount)
    }
}
