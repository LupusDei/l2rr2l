import SwiftUI

/// Game flow for Stretchy Blend (spec 3.1): listen, slide Cutisie down the
/// rainbow to stretch the sounds, zoom to squeeze them into the word, then pick
/// the matching picture. Wrong picks climb the 4-step hint ladder; nothing is
/// ever a fail.
@MainActor
@Observable
final class StretchyBlendModel {
    enum Phase: Equatable { case intro, listen, slide, zoomReady, zooming, pick, won, roundDone }

    static let itemsPerRound = 6
    /// Start pad on the slide before the first tile (fraction of the slide).
    static let pad: CGFloat = 0.12

    private(set) var items: [BlendItem]
    private(set) var index = 0
    private(set) var phase: Phase = .intro
    /// Where Cutisie sits on the slide, 0...1.
    var position: CGFloat = 0
    private(set) var litTile: Int?
    private(set) var pulseTile: Int?
    private(set) var cards: [Word] = []
    private(set) var wiggleCard: Word?
    private(set) var glowCard: Word?
    private(set) var burstCard: Word?
    private(set) var hintLevel = 0
    private(set) var wiggleCount = 0
    private(set) var tilesBounce = 0

    @ObservationIgnored private var visited: Set<Int> = []
    @ObservationIgnored private var usedHelp = false
    @ObservationIgnored private var cardsShownAt = Date()
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private var needsListen = true
    @ObservationIgnored private let services: AppServices

    var item: BlendItem { items[index] }
    var graphemes: [String] { item.word.graphemes }
    /// Sound key per tile ("" for a silent magic e).
    var sounds: [String] { item.word.soundKeys }
    var game: GameID { .stretchyBlend }

    init(services: AppServices) {
        self.services = services
        items = SessionPlanner(progress: services.progress).pictureItems(Self.itemsPerRound)
        if items.isEmpty { items = WordBank.stage1Blends }
    }

    // MARK: Flow

    func start() async {
        await services.phonemes.prepare(items.flatMap(\.word.soundKeys))
        try? await Task.sleep(for: .seconds(1.0))
        await beginItem()
    }

    private func beginItem() async {
        position = 0
        litTile = nil
        pulseTile = nil
        cards = []
        wiggleCard = nil
        glowCard = nil
        burstCard = nil
        hintLevel = 0
        visited = []
        usedHelp = false
        if needsListen || index < 2 {
            needsListen = false
            await listen()
        }
        phase = .slide
        services.mascot.react(.point)
        await services.voice.say(index == 0 ? "Now you! Slide Cutisie slowly down the rainbow." : "Slide Cutisie slowly.")
    }

    /// Spec step 1: the Star Voice models the stretched word while the tiles
    /// light in time and Cutisie glides along.
    private func listen() async {
        phase = .listen
        services.mascot.react(.listen)
        await services.voice.say("Listen.")
        await modelStretch()
        position = 0
    }

    private func modelStretch() async {
        let n = graphemes.count
        await services.phonemes.stretch(sounds, perSound: 0.7) { [weak self] i in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                self.litTile = i >= 0 ? i : nil
                self.position = i >= 0 ? Self.pad + (1 - Self.pad) * (CGFloat(i) + 0.5) / CGFloat(n) : 1
            }
        }
    }

    // MARK: Sliding

    func slideChanged(to t: CGFloat) {
        guard [.slide, .zoomReady, .pick].contains(phase) else { return }
        position = min(max(t, 0), 1)
        let tile = tileIndex(at: position)
        if tile != litTile {
            litTile = tile
            if let tile {
                visited.insert(tile)
                services.phonemes.hold(sounds[tile])
            } else {
                services.phonemes.release()
            }
        }
        resetStuckTimer()
    }

    func slideEnded() {
        services.phonemes.release()
        let complete = visited.count == graphemes.count && position > 0.97
        litTile = nil
        visited = []
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { position = 0 }
        guard complete else { return }
        switch phase {
        case .slide:
            if index < 2 {
                Task { await zoom() }
            } else {
                phase = .zoomReady
                services.feedback.play(.star)
                services.voice.announce("Now zoom! Slide fast!")
            }
        case .zoomReady:
            Task { await zoom() }
        default:
            break
        }
    }

    private func tileIndex(at t: CGFloat) -> Int? {
        guard t >= Self.pad else { return nil }
        let n = graphemes.count
        return min(n - 1, Int((t - Self.pad) / (1 - Self.pad) * CGFloat(n)))
    }

    /// Spec step 3: Cutisie zooms down and the sounds squeeze into the word.
    private func zoom() async {
        phase = .zooming
        services.sounds.playPack("squeal_zoom")
        services.mascot.react(.zoomSlide)
        let n = graphemes.count
        for i in 0..<n {
            withAnimation(.easeIn(duration: 0.12)) {
                litTile = i
                position = Self.pad + (1 - Self.pad) * (CGFloat(i) + 0.5) / CGFloat(n)
            }
            try? await Task.sleep(for: .milliseconds(120))
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { position = 1; litTile = nil }
        tilesBounce += 1
        await services.voice.sayWord(item.word.text)
        try? await Task.sleep(for: .milliseconds(250))
        showCards()
    }

    private func showCards() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            position = 0
            cards = ([item.word] + item.distractors).shuffled()
            phase = .pick
        }
        cardsShownAt = .now
        services.voice.announce("Which picture?")
        resetStuckTimer()
    }

    // MARK: Picking

    func pick(_ card: Word) {
        guard phase == .pick else { return }
        stuckTask?.cancel()
        if card == item.word {
            phase = .won
            burstCard = card
            tilesBounce += 1
            let helped = usedHelp || hintLevel >= 3
            services.celebrateCorrect(game: game, word: card.text, usedAudioHelp: helped,
                                      responseTime: Date().timeIntervalSince(cardsShownAt),
                                      stars: helped ? 1 : (hintLevel == 0 ? 3 : 2),
                                      line: hintLevel >= 3 ? "We did it together!" : nil)
            if hintLevel >= 3 { needsListen = true }
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                await services.voice.sayWord(card.text)
                try? await Task.sleep(for: .seconds(0.8))
                await next()
            }
        } else {
            wiggleCard = card
            wiggleCount += 1
            services.progress.recordAnswer(game: game, word: item.word.text, correct: false,
                                           errorTags: errorTags(for: card))
            Task { await climbHint(missed: true) }
        }
    }

    /// The 4-level hint ladder (learning path section 6).
    private func climbHint(missed: Bool) async {
        hintLevel = min(hintLevel + 1, 4)
        switch hintLevel {
        case 1:
            if missed { services.feedback.play(.oops) }
            services.mascot.react(missed ? .encourage : .think)
            await services.voice.say("Touch each sound.")
        case 2:
            services.feedback.play(.pop)
            pulseTile = 0
            await services.voice.say("Listen to the first sound.")
            await services.phonemes.tap(sounds[0], holdFor: 0.8)
            try? await Task.sleep(for: .seconds(0.6))
            pulseTile = nil
        case 3:
            usedHelp = true
            services.mascot.react(.think)
            await services.voice.say("Let's stretch it together.")
            await modelStretch()
            withAnimation(.spring) { position = 0 }
        default:
            usedHelp = true
            glowCard = item.word
            await services.voice.say("It says \(item.word.text). Tap \(item.word.text).")
        }
        resetStuckTimer()
    }

    private func resetStuckTimer() {
        stuckTask?.cancel()
        guard phase == .pick else { return }
        stuckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled, let self, self.phase == .pick, self.hintLevel < 4 else { return }
            await self.climbHint(missed: false)
        }
    }

    private func errorTags(for card: Word) -> [String] {
        let a = item.word.graphemes, b = card.graphemes
        guard a.count == b.count, let i = zip(a, b).enumerated().first(where: { $0.element.0 != $0.element.1 })?.offset else { return [] }
        let position = i == 0 ? "first" : (i == a.count - 1 ? "last" : "middle")
        let vowels: Set<String> = ["a", "e", "i", "o", "u"]
        if vowels.contains(a[i]) && vowels.contains(b[i]) { return ["vowel:\(a[i])-\(b[i])", "position:\(position)"] }
        if Set([a[i], b[i]]) == ["b", "d"] { return ["reversal:b-d", "position:\(position)"] }
        return ["position:\(position)"]
    }

    private func next() async {
        if index + 1 >= items.count {
            phase = .roundDone
            services.celebrateRoundComplete(game: game, line: "You stretched every word! Cutisie is so proud!")
            return
        }
        index += 1
        await beginItem()
    }

    func playAgain() {
        index = 0
        items = SessionPlanner(progress: services.progress).pictureItems(Self.itemsPerRound)
        Task { await services.phonemes.prepare(items.flatMap(\.word.soundKeys)); await beginItem() }
    }

    func stop() {
        stuckTask?.cancel()
        services.phonemes.release()
    }
}
