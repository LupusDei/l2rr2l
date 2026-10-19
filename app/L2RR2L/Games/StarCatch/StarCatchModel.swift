import SwiftUI

/// Game flow for Star Catch (spec 3.3): a star carrying a word drifts down
/// with no audio; she reads it and taps the matching picture cloud. Tapping
/// the star gives a help stretch. A heart word round flips it (the Star Voice
/// says the word, she taps it), and a sentence round ends the constellation.
/// The time from the star appearing to the right tap is the mastery latency,
/// measured silently and never shown.
@MainActor
@Observable
final class StarCatchModel {
    enum Phase: Equatable { case intro, falling, caught, roundDone }

    /// One cloud she can tap.
    struct Choice: Hashable, Identifiable {
        let id: String
        /// Emoji picture/scene, or a word for heart rounds.
        let display: String
        let isText: Bool
        let correct: Bool
        /// The id is a word with a picture card (word rounds).
        var isWordPicture = false
    }

    private(set) var items: [CatchItem]
    private(set) var index = 0
    private(set) var phase: Phase = .intro
    private(set) var choices: [Choice] = []
    private(set) var starStart = Date()
    private(set) var litLetter: Int?
    private(set) var helpUsed = false
    private(set) var wiggleChoice: Choice?
    private(set) var wiggleCount = 0
    private(set) var glowChoice: Choice?
    private(set) var caughtChoice: Choice?
    private(set) var catches = 0

    @ObservationIgnored private var hintLevel = 0
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private let services: AppServices
    /// Set when the game leaves the screen so pending steps don't keep talking.
    @ObservationIgnored private var stopped = false

    var item: CatchItem { items[index] }
    var total: Int { items.count }
    var game: GameID { .starCatch }

    /// The word on the star for word rounds (nil for heart and sentence rounds).
    var word: Word? { if case .word(let b) = item { b.word } else { nil } }

    init(services: AppServices) {
        self.services = services
        items = SessionPlanner(progress: services.progress).catchItems(6)
        if items.isEmpty { items = WordBank.stage1Blends.prefix(5).map { .word($0) } }
    }

    func start() async {
        await prepareSounds()
        try? await Task.sleep(for: .seconds(2.2))
        services.mascot.react(.point)
        await services.voice.say("Read the star, then tap its picture!")
        await launch()
    }

    private func prepareSounds() async {
        let words = items.compactMap { if case .word(let b) = $0 { b.word } else { nil } }
        await services.phonemes.prepare(words.flatMap(\.soundKeys))
    }

    private func launch() async {
        guard !stopped else { return }
        hintLevel = 0
        helpUsed = false
        litLetter = nil
        wiggleChoice = nil
        glowChoice = nil
        caughtChoice = nil
        let newChoices: [Choice]
        switch item {
        case .word(let b):
            newChoices = ([b.word] + b.distractors).map {
                Choice(id: $0.text, display: $0.picture ?? "✨", isText: false, correct: $0 == b.word, isWordPicture: true)
            }
        case .heart(let w, let options):
            newChoices = options.map { Choice(id: $0, display: $0, isText: true, correct: $0 == w) }
        case .sentence(let s):
            newChoices = ([s.picture] + s.distractors).map {
                Choice(id: $0, display: $0, isText: false, correct: $0 == s.picture)
            }
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { choices = newChoices.shuffled() }
        phase = .falling
        services.feedback.play(.whoosh)
        if case .heart(let w, _) = item {
            // heart round: the Star Voice says it, she finds it
            await services.voice.say([.line("Find the heart word"), .word(w)])
        }
        starStart = .now
        resetStuckTimer()
        #if DEBUG
        Autopilot.after(2.0) { [weak self] in
            guard let self, !self.stopped, self.phase == .falling else { return }
            if Autopilot.shouldMissThisOne, let wrong = self.choices.first(where: { !$0.correct }) {
                self.tap(wrong)
                try? await Task.sleep(for: .seconds(4))
            }
            if self.phase == .falling, let right = self.choices.first(where: \.correct) { self.tap(right) }
        }
        #endif
    }

    /// Help stretch: the letters light and sound, as in Stretchy Blend.
    func tapStar() {
        guard phase == .falling else { return }
        switch item {
        case .word:
            helpUsed = true
            resetStuckTimer()
            Task { await stretch() }
        case .heart(let w, _):
            Task { await services.voice.sayWord(w) }
        case .sentence:
            break
        }
    }

    private func stretch() async {
        guard let word else { return }
        await services.phonemes.stretch(word.soundKeys, perSound: 0.55) { [weak self] i in
            self?.litLetter = i >= 0 ? i : nil
        }
    }

    func tap(_ choice: Choice) {
        guard phase == .falling else { return }
        stuckTask?.cancel()
        if choice.correct {
            phase = .caught
            caughtChoice = choice
            catches += 1
            let helped = helpUsed || hintLevel >= 2
            let latency = Date().timeIntervalSince(starStart)
            services.sounds.playPack("star_catch")
            let recorded: String? = switch item {
            case .word(let b): b.word.text
            case .heart(let w, _): w.lowercased()
            case .sentence: nil
            }
            services.celebrateCorrect(game: game, word: recorded, usedAudioHelp: helped, responseTime: latency,
                                      stars: helped ? 1 : (latency <= 3 ? 3 : 2),
                                      line: hintLevel >= 3 ? "We did it together!" : nil)
            services.mascot.react(.catchStar)
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                // the word is spoken after the catch, as confirmation
                switch item {
                case .word(let b): await services.voice.sayWord(b.word.text)
                case .heart(let w, _): await services.voice.sayWord(w)
                case .sentence(let s): await services.voice.say(s.text)
                }
                try? await Task.sleep(for: .seconds(0.8))
                await next()
            }
        } else {
            wiggleChoice = choice
            wiggleCount += 1
            services.noteStruggle(item: item.text)
            if case .word(let b) = item {
                services.progress.recordAnswer(game: game, word: b.word.text, correct: false,
                                               errorTags: errorTags(target: b.word, chosen: choice.id))
            } else if case .heart(let w, _) = item {
                services.progress.recordAnswer(game: game, word: w.lowercased(), correct: false)
            }
            Task { await climbHint(missed: true) }
        }
    }

    private func climbHint(missed: Bool) async {
        hintLevel = min(hintLevel + 1, 4)
        switch hintLevel {
        case 1:
            if missed { services.feedback.play(.oops) }
            services.mascot.react(missed ? .encourage : .think)
            switch item {
            case .heart(let w, _): await services.voice.say([.line("Listen."), .word(w)])
            case .sentence: await services.voice.say("Read each word.")
            case .word: await services.voice.say("Touch each sound.")
            }
        case 2:
            if let word {
                litLetter = 0
                await services.phonemes.tap(word.soundKeys[0], holdFor: 0.7)
                litLetter = nil
            } else if case .sentence(let s) = item {
                helpUsed = true
                await services.voice.say(s.text)
            }
        case 3:
            helpUsed = true
            if word != nil { await stretch() }
        default:
            helpUsed = true
            glowChoice = choices.first { $0.correct }
            if let word { await services.voice.say([.line("It says"), .word(word.text)]) }
        }
        resetStuckTimer()
    }

    private func resetStuckTimer() {
        stuckTask?.cancel()
        guard phase == .falling else { return }
        stuckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled, let self, self.phase == .falling, self.hintLevel < 4 else { return }
            await self.climbHint(missed: false)
        }
    }

    private func errorTags(target: Word, chosen: String) -> [String] {
        guard let cloud = WordBank.pictures[chosen] else { return [] }
        let a = target.graphemes, b = cloud.graphemes
        guard a.count == b.count, let i = zip(a, b).enumerated().first(where: { $0.element.0 != $0.element.1 })?.offset else {
            return a.first == b.first ? ["guess:first-letter"] : []
        }
        if i == 0 { return ["position:first"] }
        let vowels: Set<String> = ["a", "e", "i", "o", "u"]
        if vowels.contains(a[i]) && vowels.contains(b[i]) { return ["vowel:\(a[i])-\(b[i])", "position:middle"] }
        // right first letter, wrong later sound: a sign of guessing from the first letter
        return ["guess:first-letter", "position:\(i == a.count - 1 ? "last" : "middle")"]
    }

    private func next() async {
        guard !stopped else { return }
        if index + 1 >= items.count {
            phase = .roundDone
            services.celebrateRoundComplete(game: game, line: "You caught every star! Look at your constellation!")
            #if DEBUG
            Autopilot.finishRound(services)
            #endif
            return
        }
        index += 1
        await launch()
    }

    func playAgain() {
        items = SessionPlanner(progress: services.progress).catchItems(6)
        index = 0
        catches = 0
        Task {
            await prepareSounds()
            await launch()
        }
    }

    func stop() {
        stopped = true
        stuckTask?.cancel()
        services.phonemes.release()
    }
}
