import SwiftUI

/// Everything a screen or game needs, created once at launch and shared through
/// the SwiftUI environment. Games should talk to these instead of touching
/// AVFoundation / UIKit directly, so feel stays consistent across the app.
@MainActor
@Observable
final class AppServices {
    let router: Router
    let progress: ProgressStore
    let sounds: SoundEffects
    let haptics: Haptics
    /// The off-screen narrator: every instruction, word, letter sound and praise.
    let voice: StarVoice
    /// Cutisie's reactions. She never talks.
    let mascot: MascotDirector
    let celebration: CelebrationCenter
    let feedback: Feedback
    let parallax: ParallaxMotion
    /// Holdable letter sounds for blending.
    let phonemes: PhonemeEngine

    var speaker: Speaker { voice.speaker }

    init(router: Router,
         progress: ProgressStore,
         sounds: SoundEffects,
         haptics: Haptics,
         speaker: Speaker) {
        self.router = router
        self.progress = progress
        self.sounds = sounds
        self.haptics = haptics
        self.voice = StarVoice(speaker: speaker)
        self.mascot = MascotDirector(sounds: sounds)
        self.celebration = CelebrationCenter()
        self.feedback = Feedback(sounds: sounds, haptics: haptics)
        self.parallax = ParallaxMotion()
        self.phonemes = PhonemeEngine(voice: speaker.voice)
    }

    static func live() -> AppServices {
        AudioSessionConfigurator.configure()
        return AppServices(router: Router(),
                           progress: ProgressStore(),
                           sounds: SoundEffects(),
                           haptics: Haptics(),
                           speaker: Speaker())
    }

    static func preview() -> AppServices {
        AppServices(router: Router(),
                    progress: ProgressStore(fileURL: nil),
                    sounds: SoundEffects(),
                    haptics: Haptics(),
                    speaker: Speaker())
    }

    // MARK: - The moments every game shares

    /// Praise rotates so it stays fresh. Lines praise the strategy, not the child.
    private let praise = ["You read it!", "You stretched every sound!", "Super reading!",
                          "Wow, you did it!", "Yes! That's it!"]
    private var praiseIndex = 0

    /// A right answer: chime, star, a small confetti pop, Cutisie cheers and
    /// the Star Voice praises. Report `usedAudioHelp` and `responseTime` so
    /// word mastery is tracked.
    func celebrateCorrect(game: GameID,
                          word: String? = nil,
                          usedAudioHelp: Bool = false,
                          responseTime: TimeInterval? = nil,
                          stars: Int = 1,
                          line: String? = nil) {
        feedback.play(.correct)
        let sticker = progress.recordAnswer(game: game, word: word, correct: true,
                                            usedAudioHelp: usedAudioHelp, responseTime: responseTime)
        progress.awardStars(stars, game: game)
        checkMilestones()
        celebration.fire(.sparkle)
        mascot.react(.cheer)
        voice.announce(line ?? nextPraise())
        if let sticker {
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                celebrateSticker(sticker)
            }
        }
    }

    /// A miss: soft, never scary. Cutisie does her oops-and-try-again pose.
    /// `errorTags` feed error-pattern tracking (e.g. "reversal:b-d").
    func encourageRetry(game: GameID,
                        word: String? = nil,
                        errorTags: [String] = [],
                        line: String? = "Almost! Let's try again.") {
        feedback.play(.oops)
        progress.recordAnswer(game: game, word: word, correct: false, errorTags: errorTags)
        mascot.react(.encourage)
        if let line { voice.announce(line) }
    }

    /// End of a round: big celebration, dance clip, session recorded.
    func celebrateRoundComplete(game: GameID, line: String = "You did it! Cutisie is so proud!") {
        feedback.play(.fanfare)
        progress.finishSession(game: game)
        celebration.fire(.fireworks)
        mascot.react(.dance)
        voice.announce(line)
    }

    /// A word was just mastered: it joins the sticker word book.
    func celebrateSticker(_ sticker: Sticker) {
        feedback.play(.sticker)
        celebration.fire(.sticker(sticker))
        mascot.react(.dance)
        voice.announce("\(sticker.word.capitalized) goes in your sticker book!")
    }

    /// Learning path section 8 milestones that come from reading words alone.
    private func checkMilestones() {
        let readAlone = progress.wordsReadAlone
        let milestones: [(Int, String, MascotClip, String)] = [
            (1, "first-word", .levelUp, "Your very first word, all by yourself!"),
            (10, "ten-words", .bird, "Ten words read alone! Cutisie's wings are sparkling!"),
            (50, "fifty-words", .levelUp, "Fifty words! A new part of the sky is glowing!"),
            (100, "hundred-words", .bird, "One hundred words! Party time with the bird friend!"),
        ]
        for (count, id, clip, line) in milestones where readAlone >= count {
            guard progress.reachMilestone(id) else { continue }
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                feedback.play(.fanfare)
                celebration.fire(.fireworks)
                mascot.react(clip)
                await voice.say(line)
            }
            break
        }
    }

    private func nextPraise() -> String {
        defer { praiseIndex += 1 }
        return praise[praiseIndex % praise.count]
    }
}
