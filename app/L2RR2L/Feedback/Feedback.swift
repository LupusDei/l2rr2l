import Foundation

/// One call for "how this moment feels": a sound everywhere, plus a haptic on
/// iPhone. iPad has no haptics, so sounds and on-screen motion must carry the
/// feel on their own; never rely on a haptic alone to communicate anything.
@MainActor
final class Feedback {
    let sounds: SoundEffects
    let haptics: Haptics

    init(sounds: SoundEffects, haptics: Haptics) {
        self.sounds = sounds
        self.haptics = haptics
    }

    enum Moment { case tap, pick, drop, correct, oops, star, sticker, fanfare, whoosh, pop, twinkle }

    func play(_ moment: Moment) {
        switch moment {
        case .tap: sounds.play(.tap); haptics.play(.tap)
        case .pick: sounds.play(.pick); haptics.play(.pick)
        case .drop: sounds.play(.drop); haptics.play(.drop)
        case .correct: sounds.play(.correct); haptics.play(.success)
        case .oops: sounds.play(.oops); haptics.play(.gentleMiss)
        case .star: sounds.play(.star); haptics.play(.tap)
        case .sticker: sounds.play(.sticker); haptics.play(.celebrate)
        case .fanfare: sounds.play(.fanfare); haptics.play(.celebrate)
        case .whoosh: sounds.play(.whoosh)
        case .pop: sounds.play(.pop); haptics.play(.tap)
        case .twinkle: sounds.playTwinkle(); haptics.play(.pick)
        }
    }
}
