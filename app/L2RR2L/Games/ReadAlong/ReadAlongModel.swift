import SwiftUI

/// Read Along: Cutisie reads a sentence with the child, word by word.
///
/// Each sentence goes I read, we read, you read:
/// 1. **Cutisie reads.** Her horn points at each word; she sounds it out
///    (each tile lights while its sound plays and her mouth makes it), then
///    says it whole. Heart words and words the child has mastered are read
///    whole. Then she reads the sentence again, smoothly.
/// 2. **Your turn.** The child taps each word in order and reads it aloud
///    while Cutisie mouths along silently. Stuck for a while, or tapping
///    Cutisie, gets the word sounded out.
/// Later sentences can be **Fix It**: Cutisie reads it smoothly with one
/// word wrong ("The cot is sad"), and the child finds the word she got wrong.
/// That's the decoding check, and Cutisie is the silly one, never the child.
@MainActor
@Observable
final class ReadAlongModel {
    enum Phase: Equatable { case intro, cutisieReads, fixIt, yourTurn, won, roundDone }

    static let sentencesPerRound = 4

    let puppet = ReaderPuppet()
    private(set) var sentences: [ReadSentence]
    private(set) var index = 0
    private(set) var phase: Phase = .intro
    /// The word Cutisie (or the child) is on.
    private(set) var activeWord: Int?
    /// The tile being sounded out in the active word.
    private(set) var litPiece: Int?
    /// Words the child has read this turn.
    private(set) var readWords: Set<Int> = []
    private(set) var wiggleWord: Int?
    private(set) var wiggleCount = 0
    private(set) var hintWord: Int?
    /// Fix It: the word Cutisie misread, and what she said instead.
    private(set) var misread: (index: Int, said: Word)?
    private(set) var fixedWord: Int?

    @ObservationIgnored private let services: AppServices
    @ObservationIgnored private var stopped = false
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private var fixMisses = 0
    @ObservationIgnored private var helped = false
    @ObservationIgnored private var busy = false

    var sentence: ReadSentence { sentences[index] }
    var tokens: [ReadToken] { sentence.tokens }
    var game: GameID { .readAlong }
    /// The next word she should tap on her turn.
    var nextWord: Int? { phase == .yourTurn ? tokens.indices.first { !readWords.contains($0) } : nil }

    init(services: AppServices) {
        self.services = services
        let stage = services.progress.data.stage
        sentences = ReadAlongContent.round(stage: stage, count: Self.sentencesPerRound)
    }

    // MARK: Flow

    func start() async {
        await services.phonemes.prepare(sentences.flatMap { $0.tokens.flatMap(\.word.soundKeys) })
        try? await Task.sleep(for: .seconds(1.2))
        await beginSentence()
    }

    private func beginSentence() async {
        guard !stopped, !sentences.isEmpty else { return }
        activeWord = nil
        litPiece = nil
        readWords = []
        wiggleWord = nil
        hintWord = nil
        misread = nil
        fixedWord = nil
        fixMisses = 0
        helped = false
        if index >= 2, Bool.random(), let mistake = pickMistake() {
            misread = mistake
            await cutisieMisreads()
        } else {
            await cutisieReads()
            await yourTurn()
        }
    }

    /// Step 1: Cutisie sounds out and reads each word, then reads it smoothly.
    private func cutisieReads() async {
        phase = .cutisieReads
        if index == 0 { await services.voice.say("Read with Cutisie!") }
        for token in tokens {
            guard !stopped else { return }
            activeWord = token.id
            if shouldSoundOut(token) {
                await soundOut(token)
                try? await Task.sleep(for: .milliseconds(150))
            }
            await puppet.read(token.word, voice: services.voice)
            try? await Task.sleep(for: .milliseconds(350))
        }
        guard !stopped else { return }
        try? await Task.sleep(for: .milliseconds(300))
        await readSmoothly()
    }

    /// The whole sentence at an easy reading pace, each word lit as it's said.
    private func readSmoothly(swap: (index: Int, said: Word)? = nil) async {
        for token in tokens {
            guard !stopped else { return }
            activeWord = token.id
            let word = swap?.index == token.id ? swap!.said : token.word
            await puppet.read(word, voice: services.voice)
            try? await Task.sleep(for: .milliseconds(90))
        }
        activeWord = nil
    }

    private func soundOut(_ token: ReadToken) async {
        let keys = token.word.soundKeys
        await services.phonemes.stretch(keys, perSound: 0.5) { [weak self] i in
            guard let self else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { self.litPiece = i >= 0 ? i : nil }
            if i >= 0 { self.puppet.show(sound: keys[i]) } else { self.puppet.rest() }
        }
    }

    /// Heart words are read whole; so are words she has already mastered,
    /// so the modelling speeds up as she learns.
    private func shouldSoundOut(_ token: ReadToken) -> Bool {
        guard !token.isHeart, token.word.spokenSounds.count > 1 else { return false }
        return !(services.progress.data.words[token.word.text]?.isMastered ?? false)
    }

    // MARK: Your turn

    private func yourTurn() async {
        guard !stopped else { return }
        phase = .yourTurn
        activeWord = nil
        // a hop, not a video take: the rig stays up so she can mouth along
        puppet.hop()
        await services.voice.say(index == 0 ? "Your turn! Tap each word and read it." : "Your turn!")
        resetStuckTimer()
        #if DEBUG
        autoRead()
        #endif
    }

    /// She tapped a word on her turn.
    func tap(_ i: Int) {
        switch phase {
        case .yourTurn: tapOnTurn(i)
        case .fixIt: tapToFix(i)
        default: break
        }
    }

    private func tapOnTurn(_ i: Int) {
        guard let next = nextWord, !busy else { return }
        guard i == next else {
            // not that one yet: the next word bounces to show where she is
            services.feedback.play(.tap)
            wiggleWord = next
            wiggleCount += 1
            return
        }
        services.feedback.play(.twinkle)
        hintWord = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            readWords.insert(i)
            activeWord = i
        }
        // Cutisie mouths it with her, no sound: the child does the reading
        Task { await puppet.mouth(tokens[i].word); puppet.rest() }
        if readWords.count == tokens.count {
            stuckTask?.cancel()
            Task { await sentenceRead() }
        } else {
            resetStuckTimer()
        }
    }

    /// Tapping Cutisie on her turn: she sounds out the word the child is on.
    func askCutisie() {
        guard phase == .yourTurn, let next = nextWord else {
            services.sounds.playPack(["giggle", "squeak_happy", "coo"].randomElement()!)
            puppet.hop()
            return
        }
        Task { await help(with: next) }
    }

    private func help(with i: Int) async {
        guard !busy else { return }
        busy = true
        helped = true
        stuckTask?.cancel()
        hintWord = i
        activeWord = i
        let token = tokens[i]
        if !token.isHeart, token.word.spokenSounds.count > 1 { await soundOut(token) }
        await puppet.read(token.word, voice: services.voice)
        activeWord = nil
        busy = false
        resetStuckTimer()
    }

    private func resetStuckTimer() {
        stuckTask?.cancel()
        guard phase == .yourTurn, let next = nextWord else { return }
        stuckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, let self, self.nextWord == next else { return }
            self.hintWord = next
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, self.nextWord == next else { return }
            await self.help(with: next)
        }
    }

    private func sentenceRead() async {
        phase = .won
        activeWord = nil
        try? await Task.sleep(for: .milliseconds(400))
        puppet.hop()
        // her reading aloud can't be checked here, so words aren't scored
        // (Fix It is the check); the round still earns stars
        let clean = !helped
        services.celebrateCorrect(game: game, usedAudioHelp: !clean, stars: clean ? 3 : 2,
                                  line: clean ? "You read it all!" : "We read it together!")
        if let star = sentence.star {
            try? await Task.sleep(for: .milliseconds(500))
            services.celebration.comeAlive(star)
        }
        try? await Task.sleep(for: .seconds(3.2))
        await next()
    }

    // MARK: Fix It

    /// A decodable word with a recorded one-tile neighbour, for Cutisie to misread.
    private func pickMistake() -> (index: Int, said: Word)? {
        let options = tokens.filter { !$0.isHeart }.shuffled()
        for token in options {
            if let wrong = ReadAlongContent.nearMiss(for: token.word) { return (token.id, wrong) }
        }
        return nil
    }

    private func cutisieMisreads() async {
        phase = .cutisieReads
        await services.voice.say("Cutisie will read this one.")
        await readSmoothly(swap: misread)
        guard !stopped else { return }
        services.sounds.playPack("gasp_delight")
        services.mascot.react(.think)
        phase = .fixIt
        await services.voice.say("Oops! Tap the word Cutisie got wrong.")
        #if DEBUG
        autoFix()
        #endif
    }

    private func tapToFix(_ i: Int) {
        guard let misread, !busy else { return }
        if i == misread.index {
            busy = true
            fixedWord = i
            services.feedback.play(.correct)
            puppet.oops()
            services.sounds.playPack("bonk")
            services.progress.recordAnswer(game: game, word: tokens[i].word.text, correct: true,
                                           usedAudioHelp: fixMisses > 0)
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                services.sounds.playPack("giggle")
                await services.voice.say("You fixed it!")
                activeWord = i
                await soundOut(tokens[i])
                await puppet.read(tokens[i].word, voice: services.voice)
                try? await Task.sleep(for: .milliseconds(300))
                busy = false
                await readSmoothly()
                await yourTurn()
            }
        } else {
            fixMisses += 1
            wiggleWord = i
            wiggleCount += 1
            services.feedback.play(.oops)
            services.noteStruggle(item: tokens[misread.index].word.text)
            if fixMisses >= 2 { hintWord = misread.index }
            busy = true
            Task {
                activeWord = i
                await puppet.read(tokens[i].word, voice: services.voice)
                activeWord = nil
                await services.voice.say("That one's right. Find the wrong one!")
                busy = false
            }
        }
    }

    // MARK: Round

    private func next() async {
        guard !stopped else { return }
        if index + 1 >= sentences.count {
            phase = .roundDone
            services.celebrateRoundComplete(game: game, line: "You read with Cutisie! She loves story time!")
            #if DEBUG
            Autopilot.finishRound(services)
            #endif
            return
        }
        index += 1
        await beginSentence()
    }

    func playAgain() {
        let recent = Set(sentences.map(\.id))
        sentences = ReadAlongContent.round(stage: services.progress.data.stage, count: Self.sentencesPerRound,
                                           skipping: recent)
        index = 0
        Task {
            await services.phonemes.prepare(sentences.flatMap { $0.tokens.flatMap(\.word.soundKeys) })
            await beginSentence()
        }
    }

    func stop() {
        stopped = true
        stuckTask?.cancel()
        services.phonemes.release()
        puppet.rest()
    }

    #if DEBUG
    private func autoRead() {
        Autopilot.after(1.0) { [weak self] in
            guard let self else { return }
            while !self.stopped, self.phase == .yourTurn, let next = self.nextWord {
                if !self.busy { self.tap(next) }
                try? await Task.sleep(for: .seconds(0.9))
            }
        }
    }

    private func autoFix() {
        Autopilot.after(1.5) { [weak self] in
            guard let self, !self.stopped, self.phase == .fixIt, let misread = self.misread else { return }
            if Autopilot.shouldMissThisOne, let other = self.tokens.indices.first(where: { $0 != misread.index }) {
                self.tap(other)
                try? await Task.sleep(for: .seconds(4))
            }
            if self.phase == .fixIt { self.tap(misread.index) }
        }
    }
    #endif
}
