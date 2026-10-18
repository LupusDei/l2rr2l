import SwiftUI

/// Game flow for Word Machine (spec 3.2): hear a word, build it from letter
/// tiles in the sound boxes, pull the lever, then change one letter to make
/// the next word in the chain.
@MainActor
@Observable
final class WordMachineModel {
    enum Phase: Equatable { case intro, hear, build, ready, running, chainDone }

    private(set) var chain: WordChain
    private(set) var index = 0
    private(set) var phase: Phase = .intro
    /// Letter in each sound box (nil = empty).
    private(set) var boxes: [String?] = []
    private(set) var humming: Int?
    private(set) var glowLetter: String?
    private(set) var rejectBox: Int?
    private(set) var rejectCount = 0
    private(set) var snapCount = 0
    private(set) var runCount = 0
    private(set) var poppedWord: Word?
    private(set) var builtWords: [Word] = []
    private(set) var readingIndex: Int?

    @ObservationIgnored private var misses: [Int: Int] = [:]
    @ObservationIgnored private var usedHelp = false
    @ObservationIgnored private var wordShownAt = Date()
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private let services: AppServices
    /// Set when the game leaves the screen so pending steps don't keep talking.
    @ObservationIgnored private var stopped = false

    var word: Word { chain.words[index] }
    var target: [String] { word.graphemes }
    var sounds: [String] { word.soundKeys }
    var game: GameID { .wordMachine }

    init(services: AppServices) {
        self.services = services
        chain = SessionPlanner(progress: services.progress).chain()
            ?? WordChain(id: "starter", words: ["mat", "sat", "sad"].map { Word($0, WordBank.picture($0)) }, distractors: ["p"])
    }

    func start() async {
        await services.phonemes.prepare(chain.trayLetters + chain.words.flatMap(\.soundKeys))
        boxes = Array(repeating: nil, count: target.count)
        try? await Task.sleep(for: .seconds(1.0))
        await beginWord()
    }

    private func beginWord() async {
        guard !stopped else { return }
        misses = [:]
        usedHelp = false
        glowLetter = nil
        poppedWord = nil
        phase = .hear
        if boxes.count != target.count { boxes = Array(repeating: nil, count: target.count) }
        if index == 0 {
            await services.voice.say("Let's make")
            await services.voice.sayWord(word.text)
        } else {
            services.mascot.react(.think)
            await services.voice.say("Now make it")
            await services.voice.sayWord(word.text)
        }
        await hum(all: true)
        phase = .build
        wordShownAt = .now
        resetStuckTimer()
        checkComplete()
        #if DEBUG
        Autopilot.after(1.0) { [weak self] in
            guard let self, !self.stopped else { return }
            for i in self.target.indices where self.phase == .build && self.boxes[i] != self.target[i] {
                if Autopilot.shouldMissThisOne, let wrong = self.chain.trayLetters.first(where: { $0 != self.target[i] }) {
                    self.drop(wrong, into: i)
                    try? await Task.sleep(for: .seconds(2.5))
                }
                if self.phase == .build && self.boxes[i] != self.target[i] { self.drop(self.target[i], into: i) }
                try? await Task.sleep(for: .seconds(0.8))
            }
        }
        #endif
    }

    /// The machine plays the word stretched, one box at a time.
    private func hum(all: Bool) async {
        await services.phonemes.stretch(sounds, perSound: 0.55) { [weak self] i in
            self?.humming = i >= 0 ? i : nil
        }
    }

    // MARK: Building

    /// Tap the picture bubble to hear the word again.
    func hearAgain() {
        guard phase == .build || phase == .ready else { return }
        Task {
            await services.voice.sayWord(word.text)
            await hum(all: true)
        }
        resetStuckTimer()
    }

    /// Tap a box to hear the sound that belongs in it.
    func tapBox(_ i: Int) {
        guard phase == .build || phase == .ready else { return }
        humming = i
        Task {
            await services.phonemes.tap(sounds[i], holdFor: 0.6)
            if humming == i { humming = nil }
        }
        resetStuckTimer()
    }

    /// Tapping a tray letter drops it in the first empty box. In a chain the
    /// boxes are full, so a tap only plays the letter's sound: noticing which
    /// box to change is the point, so she drags it there herself.
    func tapLetter(_ letter: String) {
        if let slot = boxes.indices.first(where: { boxes[$0] == nil }) {
            drop(letter, into: slot)
        } else {
            Task { await services.phonemes.tap(letter, holdFor: 0.4) }
        }
    }

    func drop(_ letter: String, into i: Int) {
        guard phase == .build, boxes.indices.contains(i) else { return }
        resetStuckTimer()
        if letter == target[i] {
            boxes[i] = letter
            snapCount += 1
            services.sounds.playTwinkle()
            services.haptics.play(.drop)
            humming = i
            Task {
                await services.phonemes.tap(sounds[i], holdFor: 0.45)
                if humming == i { humming = nil }
            }
            checkComplete()
        } else {
            rejectBox = i
            rejectCount += 1
            services.noteStruggle(item: word.text)
            services.feedback.play(.oops)
            misses[i, default: 0] += 1
            let position = i == 0 ? "first" : (i == target.count - 1 ? "last" : "middle")
            services.progress.recordAnswer(game: game, word: word.text, correct: false,
                                           errorTags: ["position:\(position)"])
            Task { await hint(for: i) }
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
            await hum(all: true)
        default:
            usedHelp = true
            services.mascot.react(.carryTile)
            try? await Task.sleep(for: .seconds(1.2))
            glowLetter = nil
            boxes[i] = target[i]
            snapCount += 1
            services.feedback.play(.drop)
            checkComplete()
        }
    }

    private func checkComplete() {
        guard phase == .build, boxes.count == target.count,
              zip(boxes, target).allSatisfy({ $0 == $1 }) else { return }
        stuckTask?.cancel()
        phase = .ready
        #if DEBUG
        Autopilot.after(1.5) { [weak self] in self?.pullLever() }
        #endif
        services.feedback.play(.star)
        services.voice.announce(index == 0 ? "Pull the lever!" : "Pull it!")
    }

    // MARK: Running the machine

    func pullLever() {
        guard phase == .ready else { return }
        phase = .running
        runCount += 1
        Task {
            services.feedback.play(.whoosh)
            services.sounds.playPack("magic_zap")
            try? await Task.sleep(for: .seconds(0.4))
            // light slides across the word: a mini Stretchy Blend
            await services.phonemes.stretch(sounds, perSound: 0.4) { [weak self] i in
                self?.readingIndex = i >= 0 ? i : nil
            }
            await services.voice.sayWord(word.text)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { poppedWord = word }
            services.celebrateCorrect(game: game, word: word.text, usedAudioHelp: true,
                                      responseTime: Date().timeIntervalSince(wordShownAt),
                                      stars: usedHelp ? 1 : 2)
            builtWords.append(word)
            try? await Task.sleep(for: .seconds(2.2))
            await next()
        }
    }

    private func next() async {
        guard !stopped else { return }
        if index + 1 >= chain.words.count {
            phase = .chainDone
            withAnimation { poppedWord = nil }
            // read the whole chain back, lighting each word
            for (i, w) in builtWords.enumerated() {
                readingIndex = i
                await services.voice.sayWord(w.text)
            }
            readingIndex = nil
            services.celebrateRoundComplete(game: game, line: "You built a whole word chain!")
            #if DEBUG
            Autopilot.finishRound(services)
            #endif
            return
        }
        index += 1
        await beginWord()
    }

    private func resetStuckTimer() {
        stuckTask?.cancel()
        guard phase == .build else { return }
        stuckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(9))
            guard !Task.isCancelled, let self, self.phase == .build,
                  let stuck = self.boxes.indices.first(where: { self.boxes[$0] != self.target[$0] }) else { return }
            self.misses[stuck, default: 0] += 1
            await self.hint(for: stuck)
            self.resetStuckTimer()
        }
    }

    func playAgain() {
        let chains = WordBank.chains(for: services.progress.data.stage)
        if let i = chains.firstIndex(where: { $0.id == chain.id }), !chains.isEmpty {
            chain = chains[(i + 1) % chains.count]
        }
        index = 0
        builtWords = []
        boxes = []
        Task { await start() }
    }

    func stop() {
        stopped = true
        stuckTask?.cancel()
        services.phonemes.release()
    }
}
