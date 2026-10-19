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
        self.phonemes = PhonemeEngine()
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

    // MARK: Session limits (learning path 5: cut short after 3 struggles in
    // a row or 15 minutes, but always end at the celebration)

    @ObservationIgnored private var struggleStreak = 0
    @ObservationIgnored private var lastStruggle: String?
    static let sessionMinutes: Double = 15

    /// A game reports a miss on an item. Counted once per item.
    func noteStruggle(item: String) {
        streak = 0
        guard router.inSession, item != lastStruggle else { return }
        lastStruggle = item
        struggleStreak += 1
    }

    /// Called when an item is finished: a clean item resets the streak; after
    /// three struggled items in a row the session wraps up with the treasure.
    private func itemFinished(_ item: String?) {
        guard router.inSession else { struggleStreak = 0; return }
        if item == nil || item != lastStruggle { struggleStreak = 0 }
        lastStruggle = nil
        if struggleStreak >= 3 {
            struggleStreak = 0
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                await voice.say("You worked so hard today! Let's visit the treasure.")
                router.endSessionEarly()
            }
        }
    }

    /// True once today's session has run 15 minutes.
    var sessionTimeUp: Bool {
        guard let start = router.sessionStarted else { return false }
        return Date().timeIntervalSince(start) > Self.sessionMinutes * 60
    }

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
        itemFinished(word)
        streakStep(clean: !usedAudioHelp)
        checkMilestones()
        celebration.fire(Self.variant(after: &lastVariant))
        if streak != 5 { mascot.react(.cheer) }
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
        streak = 0
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
        voice.announce([.word(sticker.word), .line("goes in your sticker book!")])
    }

    // MARK: Streaks (game spec 4: rainbow trail at 3, a swoop at 5, aurora at 10)

    private(set) var streak = 0
    @ObservationIgnored private var lastVariant = -1

    /// Misses reset it quietly; games call this on a wrong answer.
    func breakStreak() { streak = 0 }

    private func streakStep(clean: Bool) {
        guard clean else { streak = 0; return }
        streak += 1
        // the chime climbs with the streak
        for _ in 0..<min(streak, 4) { sounds.playTwinkle() }
        switch streak {
        case 3: celebration.fire(.rainbow)
        case 5:
            celebration.fire(.starShower)
            mascot.react(.streak)
        case 10, 15, 20:
            celebration.fire(.aurora)
            mascot.react(.streak)
        default: break
        }
    }

    private static func variant(after last: inout Int) -> CelebrationCenter.Kind {
        let options = CelebrationCenter.Kind.rightAnswerVariants
        var i = Int.random(in: 0..<options.count)
        if i == last { i = (i + 1) % options.count }
        last = i
        return options[i]
    }

    /// Learning path section 8 milestones that come from reading words alone.
    private func checkMilestones() {
        let readAlone = progress.wordsReadAlone
        // (words read alone, id, learning-path milestone number, clip, line)
        let milestones: [(Int, String, Int, MascotClip, String)] = [
            (1, "first-word", 2, .levelUp, "Your very first word, all by yourself!"),
            (10, "ten-words", 3, .bird, "Ten words read alone! Cutisie's wings are sparkling!"),
            (50, "fifty-words", 6, .levelUp, "Fifty words! A new part of the sky is glowing!"),
            (100, "hundred-words", 9, .bird, "One hundred words! Party time with the bird friend!"),
        ]
        for (count, id, number, clip, line) in milestones where readAlone >= count {
            guard progress.reachMilestone(id) else { continue }
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                celebrateMilestone(number, clip: clip, line: line)
            }
            break
        }
    }

    /// A big milestone: the full-screen scene when bundled, else fireworks and a clip.
    func celebrateMilestone(_ number: Int, clip: MascotClip, line: String) {
        feedback.play(.fanfare)
        celebration.fire(.fireworks)
        if !celebration.playMilestone(number) {
            mascot.react(clip)
        }
        voice.announce(line)
    }

    private func nextPraise() -> String {
        defer { praiseIndex += 1 }
        return praise[praiseIndex % praise.count]
    }
}
