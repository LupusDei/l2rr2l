import SwiftUI

/// Word Machine (design v2, 4.2): hear a word, build it from jelly letter
/// tiles, pull the lever, watch the thing come out of the chute, then change
/// one letter to make the next word. The rules live in `WordMachineEngine`;
/// this class adds the Star Voice, sounds, hints and Cutisie.
@MainActor
@Observable
final class WordMachineModel {
    typealias State = WordMachineEngine.State

    private(set) var engine: WordMachineEngine
    private(set) var humming: Int?
    private(set) var glowLetter: String?
    private(set) var rejectBox: Int?
    private(set) var rejectCount = 0
    private(set) var snapBox: Int?
    private(set) var snapCount = 0
    private(set) var runCount = 0
    private(set) var readingIndex: Int?
    /// A tray letter she picked up, waiting for a box tap.
    private(set) var heldLetter: String?
    /// Bumps when the built word should come alive (letters morph into the thing).
    private(set) var aliveCount = 0

    @ObservationIgnored private var explainedPickUp = false
    /// Change steps left where the changing letter pops out for her (per app run).
    static var changeScaffolds = 3
    @ObservationIgnored private var misses: [Int: Int] = [:]
    @ObservationIgnored private var usedHelp = false
    @ObservationIgnored private var wordShownAt = Date()
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private let services: AppServices
    /// Set when the game leaves the screen so pending steps don't keep talking.
    @ObservationIgnored private var stopped = false

    var phase: State { engine.state }
    var word: Word { engine.word }
    var target: [String] { engine.target }
    var boxes: [String?] { engine.slots }
    var tray: [String] { engine.tray }
    var builtWords: [Word] { engine.built }
    var sounds: [String] { word.soundKeys }
    var game: GameID { .wordMachine }
    var chain: WordChain { engine.chain }

    init(services: AppServices, chain: WordChain? = nil) {
        self.services = services
        let chosen = chain
            ?? SessionPlanner(progress: services.progress).chain()
            ?? WordChain(id: "starter", words: ["mat", "sat", "sad"].map { Word($0, WordBank.picture($0)) }, distractors: ["p"])
        engine = WordMachineEngine(chain: chosen)
    }

    func start() async {
        await services.phonemes.prepare(chain.words.flatMap { $0.graphemes + $0.soundKeys } + ["a", "i", "o", "e", "u", "s", "m", "t", "p", "n"])
        try? await Task.sleep(for: .seconds(1.0))
        await beginWord()
    }

    private func beginWord() async {
        guard !stopped else { return }
        misses = [:]
        usedHelp = false
        glowLetter = nil
        heldLetter = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { engine.beginWord() }
        let changeStep = engine.isChangeStep
        if !changeStep {
            await services.voice.say([.line("Let's make"), .word(word.text)])
        } else {
            services.mascot.react(.think)
            await services.voice.say([.line("Now make it"), .word(word.text)])
            // The old word stays in the boxes so she changes just one sound.
            // Until she's got the idea, the letter that changes pops out so
            // she sees an empty box to fill; after that she finds it herself.
            if Self.changeScaffolds > 0, let changing = engine.wrongSlots.first {
                Self.changeScaffolds -= 1
                await services.voice.say("Change one letter!")
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { engine.clear(changing) }
                services.feedback.play(.pop)
                rejectBox = changing
                rejectCount += 1
            } else {
                await services.voice.say("Which sound changes?")
                explainedPickUp = false
            }
        }
        guard !stopped else { return }
        await hum()
        wordShownAt = .now
        resetStuckTimer()
        #if DEBUG
        autoplay()
        #endif
    }

    /// The machine hums the word stretched, one box at a time.
    private func hum() async {
        await services.phonemes.stretch(sounds, perSound: 0.55) { [weak self] i in
            self?.humming = i >= 0 ? i : nil
        }
    }

    // MARK: Building

    /// Tap the picture bubble to hear the word again.
    func hearAgain() {
        guard phase == .building || phase == .complete else { return }
        Task {
            await services.voice.sayWord(word.text)
            await hum()
        }
        resetStuckTimer()
    }

    /// Tap a box: drop a picked-up letter in, or hear the sound that belongs there.
    func tapBox(_ i: Int) {
        guard phase == .building || phase == .complete else { return }
        if let letter = heldLetter, phase == .building {
            heldLetter = nil
            drop(letter, into: i)
            return
        }
        humming = i
        services.sounds.playTwinkle()
        Task {
            await services.phonemes.tap(sounds[i], holdFor: 0.6)
            if humming == i { humming = nil }
        }
        resetStuckTimer()
    }

    /// Tap a tray letter: its sound plays. If a box is empty it goes in the
    /// first empty one; otherwise (a change step) it's picked up and she taps
    /// the box it belongs in. The app never chooses the box for her.
    func tapLetter(_ letter: String) {
        guard phase == .building else { return }
        services.phonemes.hold(letter)
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            services.phonemes.release()
        }
        if let slot = boxes.indices.first(where: { boxes[$0] == nil }) {
            drop(letter, into: slot)
        } else {
            heldLetter = heldLetter == letter ? nil : letter
            services.feedback.play(.pick)
            if heldLetter != nil && !explainedPickUp {
                explainedPickUp = true
                services.voice.announce("Now tap the box it goes in!")
            }
        }
    }

    func drop(_ letter: String, into i: Int) {
        guard phase == .building else { return }
        resetStuckTimer()
        switch engine.place(letter, at: i) {
        case .accepted, .completed:
            snapped(i)
            if phase == .complete { completed() }
        case .rejected:
            rejectBox = i
            rejectCount += 1
            services.noteStruggle(item: word.text)
            services.feedback.play(.oops)
            misses[i, default: 0] += 1
            let position = i == 0 ? "first" : (i == target.count - 1 ? "last" : "middle")
            services.progress.recordAnswer(game: game, word: word.text, correct: false,
                                           errorTags: ["position:\(position)"])
            Task { await hint(for: i) }
        case .ignored:
            break
        }
    }

    private func snapped(_ i: Int) {
        snapBox = i
        snapCount += 1
        services.sounds.playTwinkle()
        services.haptics.play(.drop)
        humming = i
        Task {
            await services.phonemes.tap(sounds[i], holdFor: 0.45)
            if humming == i { humming = nil }
        }
    }

    /// The hint ladder for the box she's stuck on.
    private func hint(for i: Int) async {
        switch misses[i, default: 1] {
        case 1:
            services.mascot.react(.think)
            await services.voice.say("Touch each sound.")
        case 2:
            humming = i
            await services.phonemes.tap(sounds[i], holdFor: 0.8)
            humming = nil
        case 3:
            usedHelp = true
            glowLetter = target[i]
            await hum()
        default:
            usedHelp = true
            services.mascot.react(.carryTile)
            try? await Task.sleep(for: .seconds(1.2))
            glowLetter = nil
            if engine.autoFill(i) != .ignored { snapped(i) }
            if phase == .complete { completed() }
        }
    }

    private func completed() {
        stuckTask?.cancel()
        heldLetter = nil
        glowLetter = nil
        services.feedback.play(.star)
        services.voice.announce(engine.index == 0 ? "Pull the lever!" : "Pull it!")
        #if DEBUG
        Autopilot.after(1.5) { [weak self] in self?.pullLever() }
        #endif
    }

    // MARK: Running the machine

    func pullLever() {
        guard engine.pullLever() else { return }
        runCount += 1
        Task {
            services.feedback.play(.whoosh)
            services.sounds.playPack("magic_zap")
            try? await Task.sleep(for: .seconds(0.4))
            // light slides across the word: a mini Stretchy Blend
            await services.phonemes.stretch(sounds, perSound: 0.4) { [weak self] i in
                self?.readingIndex = i >= 0 ? i : nil
            }
            guard !stopped else { return }
            // hit-pause, then the letters come alive as the thing
            try? await Task.sleep(for: .milliseconds(70))
            engine.finishRun()
            aliveCount += 1
            services.celebration.comeAlive(word)
            await services.voice.sayWord(word.text)
            services.celebrateCorrect(game: game, word: word.text, usedAudioHelp: true,
                                      responseTime: Date().timeIntervalSince(wordShownAt),
                                      stars: usedHelp ? 1 : 2)
            try? await Task.sleep(for: .seconds(2.0))
            await next()
        }
    }

    private func next() async {
        guard !stopped else { return }
        engine.finishReveal()
        if phase == .scene {
            // the chain's things line up and are read back in order
            for (i, w) in builtWords.enumerated() {
                guard !stopped else { return }
                readingIndex = i
                await services.voice.sayWord(w.text)
                try? await Task.sleep(for: .milliseconds(200))
            }
            readingIndex = nil
            services.celebrateRoundComplete(game: game, line: "You built a whole word chain!")
            #if DEBUG
            Autopilot.finishRound(services)
            #endif
            return
        }
        await beginWord()
    }

    private func resetStuckTimer() {
        stuckTask?.cancel()
        guard phase == .building else { return }
        stuckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(9))
            guard !Task.isCancelled, let self, self.phase == .building,
                  let stuck = self.engine.wrongSlots.first else { return }
            self.misses[stuck, default: 0] += 1
            await self.hint(for: stuck)
            self.resetStuckTimer()
        }
    }

    func playAgain() {
        let chains = WordBank.chains(for: services.progress.data.stage)
        var nextChain = chain
        if let i = chains.firstIndex(where: { $0.id == chain.id }), !chains.isEmpty {
            nextChain = chains[(i + 1) % chains.count]
        } else if let first = chains.first {
            nextChain = first
        }
        engine = WordMachineEngine(chain: nextChain)
        readingIndex = nil
        Task { await start() }
    }

    func stop() {
        stopped = true
        stuckTask?.cancel()
        services.phonemes.release()
    }

    #if DEBUG
    private func autoplay() {
        Autopilot.after(1.0) { [weak self] in
            guard let self, !self.stopped else { return }
            for i in self.engine.wrongSlots where self.phase == .building {
                if Autopilot.shouldMissThisOne, let wrong = self.tray.first(where: { $0 != self.target[i] }) {
                    self.drop(wrong, into: i)
                    try? await Task.sleep(for: .seconds(2.5))
                }
                if self.phase == .building && self.boxes[i] != self.target[i] { self.drop(self.target[i], into: i) }
                try? await Task.sleep(for: .seconds(0.8))
            }
        }
    }
    #endif
}
