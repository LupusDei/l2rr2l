import SwiftUI

/// Game flow for Star Catch (spec 3.3): a star carrying a word drifts down
/// with no audio; she reads it and taps the matching picture cloud. Tapping
/// the star gives a help stretch. Five catches complete a constellation.
/// The time from the star appearing to the right tap is the mastery latency,
/// measured silently and never shown.
@MainActor
@Observable
final class StarCatchModel {
    enum Phase: Equatable { case intro, falling, caught, roundDone }

    static let catchesPerRound = 5

    private(set) var items: [BlendItem]
    private(set) var index = 0
    private(set) var phase: Phase = .intro
    private(set) var clouds: [Word] = []
    /// When the current star appeared (drives its fall).
    private(set) var starStart = Date()
    private(set) var litLetter: Int?
    private(set) var helpUsed = false
    private(set) var wiggleCloud: Word?
    private(set) var wiggleCount = 0
    private(set) var glowCloud: Word?
    private(set) var caughtCloud: Word?
    private(set) var catches = 0
    private(set) var bump = 0

    @ObservationIgnored private var hintLevel = 0
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private let services: AppServices

    var item: BlendItem { items[index] }
    var word: Word { item.word }
    var game: GameID { .starCatch }

    init(services: AppServices) {
        self.services = services
        items = Array(WordBank.stage1Blends.shuffled().prefix(Self.catchesPerRound))
    }

    func start() async {
        await services.phonemes.prepare(items.flatMap(\.word.graphemes))
        try? await Task.sleep(for: .seconds(2.2))
        services.mascot.react(.point)
        await services.voice.say("Read the star, then tap its picture!")
        launch()
    }

    private func launch() {
        hintLevel = 0
        helpUsed = false
        litLetter = nil
        wiggleCloud = nil
        glowCloud = nil
        caughtCloud = nil
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            clouds = ([item.word] + item.distractors).shuffled()
        }
        starStart = .now
        phase = .falling
        services.feedback.play(.whoosh)
        resetStuckTimer()
    }

    /// Help stretch: the letters light and sound, as in Stretchy Blend.
    func tapStar() {
        guard phase == .falling else { return }
        helpUsed = true
        resetStuckTimer()
        Task { await stretch() }
    }

    private func stretch() async {
        await services.phonemes.stretch(word.graphemes, perSound: 0.55) { [weak self] i in
            self?.litLetter = i >= 0 ? i : nil
        }
    }

    func tapCloud(_ cloud: Word) {
        guard phase == .falling else { return }
        stuckTask?.cancel()
        if cloud == word {
            phase = .caught
            caughtCloud = cloud
            catches += 1
            let helped = helpUsed || hintLevel >= 2
            let latency = Date().timeIntervalSince(starStart)
            services.sounds.playPack("star_catch")
            services.celebrateCorrect(game: game, word: word.text, usedAudioHelp: helped, responseTime: latency,
                                      stars: helped ? 1 : (latency <= 3 ? 3 : 2),
                                      line: hintLevel >= 3 ? "We did it together!" : nil)
            services.mascot.react(.catchStar)
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                // the word is spoken after the catch, as confirmation
                await services.voice.sayWord(word.text)
                try? await Task.sleep(for: .seconds(1.0))
                await next()
            }
        } else {
            wiggleCloud = cloud
            wiggleCount += 1
            bump += 1
            services.progress.recordAnswer(game: game, word: word.text, correct: false,
                                           errorTags: errorTags(for: cloud))
            Task { await climbHint(missed: true) }
        }
    }

    private func climbHint(missed: Bool) async {
        hintLevel = min(hintLevel + 1, 4)
        switch hintLevel {
        case 1:
            if missed { services.feedback.play(.oops) }
            services.mascot.react(missed ? .encourage : .think)
            await services.voice.say("Touch each sound.")
        case 2:
            litLetter = 0
            await services.phonemes.tap(word.graphemes[0], holdFor: 0.7)
            litLetter = nil
        case 3:
            helpUsed = true
            await stretch()
        default:
            helpUsed = true
            glowCloud = word
            await services.voice.say("It says")
            await services.voice.sayWord(word.text)
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

    private func errorTags(for cloud: Word) -> [String] {
        let a = word.graphemes, b = cloud.graphemes
        guard a.count == b.count, let i = zip(a, b).enumerated().first(where: { $0.element.0 != $0.element.1 })?.offset else { return [] }
        if i == 0 { return ["position:first"] }
        let vowels: Set<String> = ["a", "e", "i", "o", "u"]
        if vowels.contains(a[i]) && vowels.contains(b[i]) { return ["vowel:\(a[i])-\(b[i])", "position:middle"] }
        // right first letter, wrong later sound: a sign of guessing from the first letter
        return ["guess:first-letter", "position:\(i == a.count - 1 ? "last" : "middle")"]
    }

    private func next() async {
        if index + 1 >= items.count {
            phase = .roundDone
            services.celebrateRoundComplete(game: game, line: "You caught every star! Look at your constellation!")
            return
        }
        index += 1
        launch()
    }

    func playAgain() {
        items = Array(WordBank.stage1Blends.shuffled().prefix(Self.catchesPerRound))
        index = 0
        catches = 0
        Task {
            await services.phonemes.prepare(items.flatMap(\.word.graphemes))
            launch()
        }
    }

    func stop() {
        stuckTask?.cancel()
        services.phonemes.release()
    }
}
