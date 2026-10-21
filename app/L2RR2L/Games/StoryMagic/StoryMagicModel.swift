import SwiftUI

/// Story Magic (design/story-magic.md): a round is one tiny story. Cutisie
/// dreams each page as a ghostly picture, and the child's words make it real.
///
/// - **Pick It:** one word is missing; she reads three words that differ by
///   one sound and taps the one that makes the picture. A wrong word makes a
///   silly scene and pops back out.
/// - **Make It:** the words are scrambled; she taps them into the sentence in
///   order. Right order: the scene arranges itself. Things swapped: the silly
///   version plays out. Otherwise the words in the right place lock and the
///   rest hop back.
/// - **Silly or not?** A sentence with no picture; she decides if it makes sense.
/// - **The book:** the Star Voice reads her whole story back.
@MainActor
@Observable
final class StoryMagicModel {
    enum Mode: String { case pick, make, judge }
    enum Phase: String { case intro, pick, make, judge, won, book, roundDone }

    private(set) var story: Story
    private(set) var phase: Phase = .intro
    /// 0..<pages for the story pages, `pages` for the meaning check.
    private(set) var page = 0
    private(set) var line: StoryLine
    private(set) var tokens: [ReadToken] = []
    private(set) var show: StageShow = .empty
    private(set) var dream: StoryScene?
    private(set) var celebrate = 0
    /// The word the Star Voice is reading, lit in the sentence.
    private(set) var litWord: Int?
    /// A soft glow on what to do next when she's been stuck a while.
    private(set) var hint: Int?

    // Make It
    /// Token index sitting in each slot (slot i should hold token i).
    private(set) var slots: [Int?] = []
    /// Slots filled for her (scaffolding) or locked after a check.
    private(set) var locked: Set<Int> = []
    /// Words still on the clouds, in their scrambled order.
    private(set) var tray: [Int] = []
    private(set) var hopCount = 0

    // Pick It
    private(set) var gapIndex: Int?
    private(set) var choices: [Word] = []
    private(set) var filled: Word?
    private(set) var tried: Set<String> = []

    // Silly or not
    private(set) var answered: Bool?

    // The book
    private(set) var bookPage = 0

    var pages: Int { story.pages.count }
    var mode: Mode { page >= pages ? .judge : modes[page] }
    var game: GameID { .storyMagic }

    @ObservationIgnored private let services: AppServices
    @ObservationIgnored private var modes: [Mode] = []
    @ObservationIgnored private var stopped = false
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private var helped = false
    @ObservationIgnored private var missed = false
    @ObservationIgnored private var started = Date()
    @ObservationIgnored private var seenModes: Set<Mode> = []
    private(set) var busy = false

    init(services: AppServices, story: Story? = nil) {
        self.services = services
        let p = services.progress.data
        let chosen = story ?? StoryContent.pick(stage: p.stage, read: p.storiesRead) ?? StoryContent.all[0]
        self.story = chosen
        line = chosen.pages[0]
        modes = Self.modes(for: chosen, session: p.games[GameID.storyMagic.rawValue]?.sessions ?? 0)
    }

    /// Pick It first (one word is easier), then Make It, then alternating.
    static func modes(for story: Story, session: Int) -> [Mode] {
        story.pages.indices.map { i in
            switch i {
            case 0: .pick
            case 1: .make
            default: (session + i).isMultiple(of: 2) ? .make : .pick
            }
        }
    }

    // MARK: Flow

    func start() async {
        try? await Task.sleep(for: .seconds(2.2))
        await beginPage()
    }

    private var stage: Int { max(services.progress.data.stage, story.stage) }

    private func beginPage() async {
        guard !stopped else { return }
        line = page < pages ? story.pages[page] : story.check
        tokens = StoryContent.tokens(line.text, stage: stage)
        litWord = nil
        hint = nil
        helped = false
        missed = false
        filled = nil
        tried = []
        answered = nil
        gapIndex = nil
        started = .now
        var m = mode
        if m == .pick {
            if let gap = StoryContent.gap(for: line, stage: stage) {
                gapIndex = gap.index
                choices = gap.choices
            } else {
                m = .make
                modes[page] = .make
            }
        }
        switch m {
        case .pick:
            dream = line.scene
            show = .loose(line.scene.things.filter { $0 != tokens[gapIndex!].word.text })
            phase = .pick
            if !seenModes.contains(.pick) {
                await services.voice.say("Read the words. Which word makes the picture?")
            } else {
                await services.voice.say("Which word makes the picture?")
            }
        case .make:
            dream = line.scene
            setUpMake()
            show = .loose(placedThings)
            phase = .make
            if !seenModes.contains(.make) {
                await services.voice.say("Put the words in order to make the picture!")
            } else {
                await services.voice.say("Make the picture!")
            }
        case .judge:
            dream = nil
            show = .empty
            phase = .judge
            services.mascot.react(.think)
            await services.voice.say("Read it. Does it make sense, or is it silly?")
        }
        seenModes.insert(m)
        started = .now
        resetStuckTimer()
        #if DEBUG
        autoPlay()
        #endif
    }

    // MARK: Make It

    /// Scaffolding grows with her: heart words placed for her at first, then
    /// just the first word, then nothing.
    private func setUpMake() {
        let done = services.progress.data.games[game.rawValue]?.correct ?? 0
        var given: Set<Int> = []
        if done < 4 {
            given = Set(tokens.filter(\.isHeart).map(\.id))
        } else if done < 10 {
            given = [0]
        }
        // always leave at least two words to place
        while tokens.count - given.count < 2, let last = given.max() { given.remove(last) }
        slots = tokens.indices.map { given.contains($0) ? $0 : nil }
        locked = given
        var loose = tokens.indices.filter { !given.contains($0) }
        repeat { loose.shuffle() } while loose.count > 1 && loose == loose.sorted()
        tray = loose
    }

    /// Picture words placed so far, for the loose stage.
    private var placedThings: [String] {
        slots.compactMap { $0 }.map { tokens[$0].word.text }.filter { line.scene.things.contains($0) }
    }

    /// She tapped a word on a cloud: it flies to the first empty slot.
    func tapTray(_ token: Int) {
        guard phase == .make, !busy, tray.contains(token), let slot = slots.firstIndex(where: { $0 == nil }) else { return }
        services.sounds.playTwinkle()
        hint = nil
        withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
            tray.removeAll { $0 == token }
            slots[slot] = token
            show = .loose(placedThings)
        }
        if !slots.contains(where: { $0 == nil }) {
            stuckTask?.cancel()
            busy = true
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                await checkSentence()
            }
        } else {
            resetStuckTimer()
        }
    }

    /// She tapped a word in the sentence: it goes back to the clouds.
    func tapSlot(_ slot: Int) {
        guard phase == .make, !busy, !locked.contains(slot), let token = slots[slot] else { return }
        services.feedback.play(.pop)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
            slots[slot] = nil
            tray.append(token)
            show = .loose(placedThings)
        }
        resetStuckTimer()
    }

    private func isRight(_ slot: Int) -> Bool {
        guard let t = slots[slot] else { return false }
        return tokens[t].shown == tokens[slot].shown
    }

    private func checkSentence() async {
        if slots.indices.allSatisfy(isRight) {
            await pageWon()
            return
        }
        missed = true
        services.noteStruggle(item: line.text)
        // the two things swapped: the silly version plays out
        let s = line.scene
        if let swapped = s.swapped, let b = s.b {
            let words = slots.map { tokens[$0!].shown.lowercased() }
            let expected = tokens.map { t -> String in
                let w = t.shown.lowercased()
                return w == s.a ? b : w == b ? s.a : w
            }
            if words == expected {
                show = .full(swapped)
                services.encourageRetry(game: game, errorTags: ["word-order"], line: nil)
                services.sounds.playPack("giggle")
                services.mascot.react(.think)
                await services.voice.say("Silly! Let's fix it.")
                try? await Task.sleep(for: .seconds(0.8))
                bounceBack { [self] slot in
                    let w = tokens[slots[slot]!].shown.lowercased()
                    return w == s.a || w == b
                }
                busy = false
                resetStuckTimer()
                return
            }
        }
        services.encourageRetry(game: game, errorTags: ["word-order"], line: nil)
        bounceBack { [self] slot in !isRight(slot) }
        await services.voice.say("Almost! Some words hopped back.")
        busy = false
        resetStuckTimer()
    }

    /// Words in the right place lock and glow; the chosen others hop back to the clouds.
    private func bounceBack(_ shouldGo: (Int) -> Bool) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            for slot in slots.indices where !locked.contains(slot) {
                if slots[slot] != nil, shouldGo(slot) {
                    tray.append(slots[slot]!)
                    slots[slot] = nil
                } else if isRight(slot) {
                    locked.insert(slot)
                }
            }
            hopCount += 1
            show = .loose(placedThings)
        }
    }

    // MARK: Pick It

    func pick(_ i: Int) {
        guard phase == .pick, !busy, i < choices.count, let gapIndex else { return }
        let choice = choices[i]
        guard !tried.contains(choice.text) else { return }
        busy = true
        stuckTask?.cancel()
        hint = nil
        services.feedback.play(.drop)
        let target = tokens[gapIndex].word
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            filled = choice
            show = .full(line.scene.replacing(target.text, with: choice.text))
        }
        Task {
            if choice.text == target.text {
                try? await Task.sleep(for: .milliseconds(500))
                await pageWon(word: target.text)
            } else {
                missed = true
                tried.insert(choice.text)
                services.noteStruggle(item: target.text)
                services.encourageRetry(game: game, word: target.text, errorTags: ["sentence-pick:\(choice.text)"], line: nil)
                try? await Task.sleep(for: .milliseconds(450))
                services.sounds.playPack(WordPicture.card(choice.text) != nil ? "giggle" : "hmm")
                await services.voice.say([.line("Oops! That says"), .word(choice.text)])
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                    filled = nil
                    show = .loose(line.scene.things.filter { $0 != target.text })
                }
                if tried.count >= 2 { hint = choices.firstIndex { $0.text == target.text } }
                busy = false
                resetStuckTimer()
            }
        }
    }

    // MARK: Silly or not

    func judge(silly: Bool) {
        guard phase == .judge, !busy, answered == nil else { return }
        busy = true
        stuckTask?.cancel()
        answered = silly
        let right = silly == (line.silly ?? false)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { show = .full(line.scene) }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            if right {
                celebrate += 1
                services.celebrateCorrect(game: game, responseTime: Date().timeIntervalSince(started), stars: 2,
                                          line: silly ? "You noticed it was silly!" : "Yes! That makes sense!")
            } else {
                services.encourageRetry(game: game, errorTags: ["meaning"],
                                        line: (line.silly ?? false) ? "Look! That one is silly." : "Look! That one makes sense.")
            }
            if line.silly ?? false {
                try? await Task.sleep(for: .milliseconds(600))
                services.sounds.playPack("giggle")
                services.mascot.react(.cheer)
            }
            await readAloud()
            try? await Task.sleep(for: .seconds(1.6))
            busy = false
            await openBook()
        }
    }

    // MARK: Help

    /// The help wing: the Star Voice reads the sentence. Counts as audio help.
    func askHelp() {
        guard phase == .pick || phase == .make || phase == .judge, !busy else { return }
        busy = true
        helped = true
        stuckTask?.cancel()
        Task {
            if !seenModes.contains(.judge) || phase != .judge {
                await services.voice.say("Asking for help is smart.")
            }
            await readAloud(lightSlots: false)
            busy = false
            resetStuckTimer()
        }
    }

    private func resetStuckTimer() {
        stuckTask?.cancel()
        guard phase == .make || phase == .pick else { return }
        let page = page
        stuckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(7))
            guard !Task.isCancelled, let self, self.page == page, !self.busy else { return }
            let next = self.nextRight
            withAnimation { self.hint = next }
            try? await Task.sleep(for: .seconds(7))
            guard !Task.isCancelled, self.page == page, !self.busy, let word = self.nextWordText else { return }
            self.helped = true
            await self.services.voice.sayWord(word)
        }
    }

    /// Make It: the tray word that belongs in the first empty slot. Pick It: the right choice.
    var nextRight: Int? {
        switch phase {
        case .make:
            guard let slot = slots.firstIndex(where: { $0 == nil }) else { return nil }
            return tray.first { tokens[$0].shown == tokens[slot].shown }
        case .pick:
            guard let gapIndex else { return nil }
            return choices.firstIndex { $0.text == tokens[gapIndex].word.text }
        default: return nil
        }
    }

    private var nextWordText: String? {
        switch phase {
        case .make: nextRight.map { tokens[$0].word.text }
        case .pick: gapIndex.map { tokens[$0].word.text }
        default: nil
        }
    }

    // MARK: Page done

    private func pageWon(word: String? = nil) async {
        phase = .won
        hint = nil
        busy = true
        let firstSentence = mode == .make && !missed && !helped
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            if mode == .make { slots = tokens.indices.map { $0 }; tray = [] }
            show = .full(line.scene)
            dream = nil
        }
        celebrate += 1
        services.sounds.playPack("magic_zap")
        let clean = !missed && !helped
        services.celebrateCorrect(game: game, word: word, usedAudioHelp: helped,
                                  responseTime: Date().timeIntervalSince(started), stars: clean ? 3 : 2,
                                  line: mode == .make ? (clean ? "You built the sentence!" : "We built it together!") : nil)
        try? await Task.sleep(for: .seconds(1.4))
        await readAloud()
        if firstSentence, services.progress.reachMilestone("first-sentence") {
            services.celebrateMilestone(4, clip: .bird, line: "You built a whole sentence! The bird friend came to see!")
            await milestoneFinished()
        }
        try? await Task.sleep(for: .seconds(1.2))
        busy = false
        page += 1
        await beginPage()
    }

    /// Waits while a full-screen milestone scene plays (it ends itself, or a tap skips it).
    private func milestoneFinished() async {
        try? await Task.sleep(for: .seconds(2.5))
        let end = Date().addingTimeInterval(14)
        while services.celebration.milestoneScene != nil, Date() < end, !stopped {
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    /// The Star Voice reads the sentence, each word lighting as it's said.
    private func readAloud(lightSlots: Bool = true) async {
        for token in tokens {
            guard !stopped else { return }
            if lightSlots { litWord = token.id }
            await services.voice.sayWord(token.word.text)
            try? await Task.sleep(for: .milliseconds(110))
        }
        litWord = nil
    }

    // MARK: The book

    private func openBook() async {
        guard !stopped else { return }
        phase = .book
        bookPage = 0
        dream = nil
        services.mascot.react(.read)
        await services.voice.say("Your story! Let's read it.")
        for i in story.pages.indices {
            guard !stopped else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { bookPage = i }
            line = story.pages[i]
            tokens = StoryContent.tokens(line.text, stage: stage)
            try? await Task.sleep(for: .milliseconds(700))
            await readAloud()
            try? await Task.sleep(for: .milliseconds(600))
        }
        guard !stopped else { return }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { bookPage = story.pages.count }
        await services.voice.say("The end!")
        services.progress.finishStory(story.id)
        // the first story's milestone scene plays before the buttons appear,
        // so a tap meant for "again" can't skip it
        if services.progress.reachMilestone("first-story") {
            try? await Task.sleep(for: .seconds(1))
            services.celebrateMilestone(7, clip: .levelUp, line: "Your first story! It goes in Cutisie's book!")
            await milestoneFinished()
        }
        guard !stopped else { return }
        phase = .roundDone
        services.celebrateRoundComplete(game: game, line: "You made a whole story! Cutisie loves it!")
        #if DEBUG
        Autopilot.finishRound(services)
        #endif
    }

    func playAgain() {
        let next = StoryContent.pick(stage: services.progress.data.stage, read: services.progress.data.storiesRead,
                                     skipping: [story.id]) ?? story
        story = next
        modes = Self.modes(for: next, session: services.progress.data.games[game.rawValue]?.sessions ?? 0)
        page = 0
        Task { await beginPage() }
    }

    func stop() {
        stopped = true
        stuckTask?.cancel()
    }

    #if DEBUG
    /// "phase busy page right wrong", for UI tests. `right`/`wrong` are a
    /// tray token or choice index (or yes/silly in the meaning check).
    var testState: String {
        var right = "-", wrong = "-"
        switch phase {
        case .make:
            right = nextRight.map(String.init) ?? "-"
            if let slot = slots.firstIndex(where: { $0 == nil }) {
                wrong = tray.first { tokens[$0].shown != tokens[slot].shown }.map(String.init) ?? "-"
            }
        case .pick:
            right = nextRight.map(String.init) ?? "-"
            wrong = choices.indices.first { $0 != nextRight && !tried.contains(choices[$0].text) }.map(String.init) ?? "-"
        case .judge:
            right = (line.silly ?? false) ? "silly" : "yes"
            wrong = (line.silly ?? false) ? "yes" : "silly"
        default: break
        }
        return "\(phase.rawValue) \(busy ? 1 : 0) \(page) \(right) \(wrong)"
    }

    private func autoPlay() {
        Autopilot.after(2.5) { [weak self] in
            guard let self else { return }
            while !self.stopped, [.pick, .make, .judge].contains(self.phase) {
                if !self.busy {
                    switch self.phase {
                    case .make:
                        if let r = self.nextRight { self.tapTray(r) }
                    case .pick:
                        if Autopilot.shouldMissThisOne, let w = self.choices.indices.first(where: { $0 != self.nextRight && !self.tried.contains(self.choices[$0].text) }) {
                            self.pick(w)
                        } else if let r = self.nextRight { self.pick(r) }
                    case .judge:
                        self.judge(silly: self.line.silly ?? false)
                    default: break
                    }
                }
                try? await Task.sleep(for: .seconds(1.1))
            }
        }
    }
    #endif
}
