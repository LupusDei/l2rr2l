import SwiftUI

/// The two "fun tests" from the learning path, run by one engine:
/// - Sparkle Check (section 3): first-launch placement. Sound match, oral
///   blending, real words of rising difficulty, heart words. Picks her
///   starting stage and her shaky sounds.
/// - Sky Trial (section 7): end-of-stage checkpoint. Stage words read alone,
///   sentences, heart words and unicorn (nonsense) words. 80% opens the next
///   world; otherwise nothing bad happens and it comes back later.
/// Every answer gets a sparkle; no score is ever shown.
@MainActor
@Observable
final class CheckModel {
    enum Kind: Equatable { case sparkleCheck, skyTrial(stage: Int), warmUp(WarmUpKind) }

    enum Question: Equatable {
        /// The Star Voice plays a sound; she taps its letter.
        case soundMatch(key: String, letter: String, choices: [String])
        /// The Star Voice says sounds apart; she picks the picture.
        case oralBlend(BlendItem)
        /// She reads a word (no audio) and picks its picture.
        case readWord(BlendItem, level: Int)
        /// The Star Voice says a heart word; she taps it.
        case heart(String, choices: [String])
        /// A nonsense word she reads aloud; a grown-up taps ✓ or ✗.
        case unicorn(Word)
        /// She reads a sentence and picks the scene.
        case sentence(Sentence)
        /// Rhyme Pop: three words are said; she pops the one that doesn't rhyme.
        case rhyme(WarmUps.RhymeSet)
        /// Wing Claps: a word is said with a flap per syllable; she taps how many.
        case claps(WarmUps.SyllableWord)
        /// Onset Slide: "/c/ ... at"; she picks the picture.
        case onset(WarmUps.Onset)

        var part: String {
            switch self {
            case .soundMatch: "sounds"
            case .oralBlend: "blending"
            case .readWord: "words"
            case .heart: "heart"
            case .unicorn: "unicorn"
            case .sentence: "sentences"
            case .rhyme: "rhyme"
            case .claps: "claps"
            case .onset: "onset"
            }
        }
    }

    enum Phase: Equatable { case intro, asking, answered, done }

    let kind: Kind
    private(set) var question: Question?
    private(set) var phase: Phase = .intro
    private(set) var choiceOrder: [String] = []
    /// What each choice shows: a picture/emoji or a word.
    private(set) var choiceDisplay: [String: String] = [:]
    private(set) var picked: String?
    private(set) var asked = 0
    private(set) var resultLine = ""
    private(set) var passed = false

    @ObservationIgnored private var queue: [Question] = []
    @ObservationIgnored private var score: [String: [Int]] = [:]
    @ObservationIgnored private var missesInARow = 0
    @ObservationIgnored private var levelResults: [Int: [Bool]] = [:]
    @ObservationIgnored private var shaky: [String] = []
    @ObservationIgnored private var shownAt = Date()
    @ObservationIgnored private let services: AppServices

    init(kind: Kind, services: AppServices) {
        self.kind = kind
        self.services = services
        switch kind {
        case .sparkleCheck: queue = Self.sparkleQuestions()
        case .skyTrial(let stage): queue = Self.trialQuestions(stage: stage)
        case .warmUp(let warmUp): queue = Self.warmUpQuestions(warmUp, count: 4)
        }
    }

    var totalPlanned: Int { asked + queue.count }

    // MARK: Building the question lists

    private static let letterOrder = Array("satpinmdgockeurhbflvwjxyz").map(String.init)

    static func sparkleQuestions() -> [Question] {
        var q: [Question] = letterOrder.map { letter in
            let others = letterOrder.filter { $0 != letter }.shuffled().prefix(2)
            return .soundMatch(key: letter, letter: letter, choices: ([letter] + others).shuffled())
        }
        q += WordBank.items(in: 1).shuffled().prefix(4).map { .oralBlend($0) }
        // real words: levels map to the stage she'd start at if this level is shaky
        for level in 1...5 {
            q += WordBank.items(in: level).shuffled().prefix(5).map { .readWord($0, level: level) }
        }
        let hearts = Curriculum.shared.stages.flatMap(\.heartWords)
        q += hearts.prefix(18).shuffled().prefix(6).map { w in
            .heart(w, choices: ([w] + hearts.filter { $0 != w }.shuffled().prefix(2)).shuffled())
        }
        // Part F: rhymes and claps
        q += warmUpQuestions(.rhymePop, count: 4) + warmUpQuestions(.wingClaps, count: 4)
        return q
    }

    static func warmUpQuestions(_ kind: WarmUpKind, count: Int) -> [Question] {
        guard let w = Curriculum.shared.warmups else { return [] }
        switch kind {
        case .rhymePop: return w.rhymeSets.shuffled().prefix(count).map { .rhyme($0) }
        case .wingClaps: return w.syllables.shuffled().prefix(count).map { .claps($0) }
        case .onsetSlide: return w.onsets.shuffled().prefix(count).map { .onset($0) }
        }
    }

    static func trialQuestions(stage: Int) -> [Question] {
        guard let s = Curriculum.shared.stage(stage) else { return [] }
        var q: [Question] = WordBank.items(in: stage).shuffled().prefix(8).map { .readWord($0, level: stage) }
        q += s.sentences.shuffled().prefix(3).map { .sentence($0) }
        let hearts = Curriculum.shared.stages.filter { $0.id <= stage }.flatMap(\.heartWords)
        q += (s.heartWords.isEmpty ? hearts : s.heartWords).shuffled().prefix(4).map { w in
            .heart(w, choices: ([w] + hearts.filter { $0 != w }.shuffled().prefix(2)).shuffled())
        }
        q += s.unicornWords.shuffled().prefix(4).map { .unicorn($0) }
        return q
    }

    // MARK: Flow

    func start() async {
        let all = queue.compactMap { q -> [String]? in
            switch q {
            case .soundMatch(let key, _, _): [key]
            case .oralBlend(let b), .readWord(let b, _): b.word.soundKeys
            case .unicorn(let w): w.soundKeys
            case .onset(let o): [o.onset]
            default: nil
            }
        }.flatMap { $0 }
        await services.phonemes.prepare(all)
        services.mascot.react(.hello)
        switch kind {
        case .sparkleCheck:
            await services.voice.say("Let's play Cutisie's Sparkle Check! There are no wrong answers. Every answer makes a sparkle.")
        case .skyTrial(let stage):
            await services.voice.say("It's a Sky Trial! Help Cutisie fly to a new world!")
        case .warmUp(.rhymePop):
            await services.voice.say("Rhyme Pop! Pop the word that doesn't rhyme.")
        case .warmUp(.wingClaps):
            await services.voice.say("Wing Claps! Count Cutisie's flaps.")
        case .warmUp(.onsetSlide):
            await services.voice.say("Onset Slide! Put the sounds together.")
        }
        await nextQuestion()
    }

    private func nextQuestion() async {
        guard !queue.isEmpty else { await finish(); return }
        let q = queue.removeFirst()
        question = q
        picked = nil
        asked += 1
        phase = .asking
        switch q {
        case .soundMatch(_, _, let choices): choiceOrder = choices
        case .oralBlend(let b), .readWord(let b, _): choiceOrder = ([b.word] + b.distractors).map(\.text).shuffled()
        case .heart(_, let choices): choiceOrder = choices
        case .sentence(let s): choiceOrder = ([s.picture] + s.distractors).shuffled()
        case .unicorn: choiceOrder = []
        case .rhyme(let set):
            let rhymes = set.words.filter { $0.text != set.odd }.shuffled().prefix(2)
            choiceOrder = (rhymes.map(\.text) + [set.odd]).shuffled()
        case .claps: choiceOrder = ["1", "2", "3"]
        case .onset(let o): choiceOrder = ([o.word] + o.distractors).shuffled()
        }
        choiceDisplay = Dictionary(uniqueKeysWithValues: choiceOrder.map { ($0, display(for: $0, in: q)) })
        await prompt(q)
        shownAt = .now
        #if DEBUG
        let asked = self.asked
        Autopilot.after(0.8) { [weak self] in
            guard let self, self.phase == .asking, self.asked == asked else { return }
            if case .unicorn = q { self.grownUp(true); return }
            let wrong = Autopilot.shouldMissThisOne ? self.choiceOrder.first { $0 != self.correctAnswer } : nil
            self.answer(wrong ?? self.correctAnswer ?? self.choiceOrder.first ?? "")
        }
        #endif
    }

    /// The right choice for the current question (nil for unicorn words).
    var correctAnswer: String? {
        switch question {
        case .soundMatch(_, let letter, _): letter
        case .oralBlend(let b), .readWord(let b, _): b.word.text
        case .heart(let w, _): w
        case .sentence(let s): s.picture
        case .rhyme(let set): set.odd
        case .claps(let w): String(w.count)
        case .onset(let o): o.word
        case .unicorn, .none: nil
        }
    }

    /// What the Star Voice says (or plays) for a question. Real-word and
    /// sentence questions are silent: she reads alone.
    func prompt(_ q: Question) async {
        switch q {
        case .soundMatch(let key, _, _):
            await services.phonemes.tap(key, holdFor: 0.7)
        case .oralBlend(let b):
            for key in b.word.spokenSounds {
                await services.phonemes.tap(key, holdFor: 0.45)
                try? await Task.sleep(for: .milliseconds(350))
            }
        case .heart(let w, _):
            await services.voice.sayWord(w)
        case .unicorn:
            services.mascot.react(.listen)
            await services.voice.say("A unicorn word! Read it out loud.")
        case .readWord, .sentence:
            break
        case .rhyme:
            for choice in choiceOrder {
                await services.voice.sayWord(choice)
                try? await Task.sleep(for: .milliseconds(250))
            }
        case .claps(let word):
            await services.voice.sayWord(word.text)
            services.mascot.react(.cheer)
            for _ in 0..<word.count {
                services.sounds.playPack("wing_flutter")
                try? await Task.sleep(for: .milliseconds(550))
            }
        case .onset(let o):
            await services.phonemes.tap(o.onset, holdFor: 0.45)
            try? await Task.sleep(for: .milliseconds(450))
            await services.voice.sayWord(o.rime)
        }
    }

    private func display(for choice: String, in q: Question) -> String {
        switch q {
        case .soundMatch, .heart: return choice
        case .claps: return String(repeating: "👏", count: Int(choice) ?? 1)
        case .rhyme(let set): return set.words.first { $0.text == choice }?.picture ?? WordBank.picture(choice) ?? "✨"
        case .onset(let o): return choice == o.word ? o.picture : (WordBank.picture(choice) ?? "✨")
        default: return WordBank.picture(choice) ?? choice
        }
    }

    /// Choices are words shown by their picture cards.
    var choicesAreWordPictures: Bool {
        switch question {
        case .oralBlend, .readWord, .rhyme, .onset: true
        default: false
        }
    }

    /// Whether choices show words (true) or pictures.
    var choicesAreText: Bool {
        switch question {
        case .soundMatch, .heart: true
        default: false
        }
    }

    func replay() {
        guard let question, phase == .asking else { return }
        Task { await prompt(question) }
    }

    func answer(_ choice: String) {
        guard phase == .asking, let q = question else { return }
        picked = choice
        let correct: Bool = switch q {
        case .soundMatch(_, let letter, _): choice == letter
        case .oralBlend(let b), .readWord(let b, _): choice == b.word.text
        case .heart(let w, _): choice == w
        case .sentence(let s): choice == s.picture
        case .unicorn: false
        case .rhyme(let set): choice == set.odd
        case .claps(let w): choice == String(w.count)
        case .onset(let o): choice == o.word
        }
        record(q, correct: correct)
    }

    /// Grown-up's ✓ / ✗ for a unicorn word, or nil if nobody is there.
    func grownUp(_ correct: Bool?) {
        guard phase == .asking, let q = question, case .unicorn = q else { return }
        if let correct {
            record(q, correct: correct)
        } else {
            sparkleAndMoveOn()
        }
    }

    private func record(_ q: Question, correct: Bool) {
        var s = score[q.part, default: [0, 0]]
        s[1] += 1
        if correct { s[0] += 1 }
        score[q.part] = s
        missesInARow = correct ? 0 : missesInARow + 1

        // feed what we learn into normal progress too
        switch q {
        case .soundMatch(_, let letter, _):
            if !correct { shaky.append(letter) }
        case .readWord(let b, let level):
            levelResults[level, default: []].append(correct)
            services.progress.recordAnswer(game: .starCatch, word: b.word.text, correct: correct,
                                           responseTime: Date().timeIntervalSince(shownAt))
        case .heart(let w, _):
            services.progress.recordAnswer(game: .starCatch, word: w.lowercased(), correct: correct,
                                           responseTime: Date().timeIntervalSince(shownAt))
        default: break
        }
        applyStopRules(after: q)
        sparkleAndMoveOn()
    }

    /// Every answer sparkles: the check never feels like a test.
    private func sparkleAndMoveOn() {
        phase = .answered
        services.sounds.playTwinkle()
        services.celebration.fire(.sparkle)
        var pause = 0.9
        if let q = question, case .unicorn(let w) = q {
            // Cutisie acts out what the unicorn word "means"
            let meaning = UnicornMeanings.meaning(for: w.text)
            services.mascot.play(take: "unicorn_word_\(meaning.clip)")
            services.voice.announce([.line("In unicorn,"), .word(w.text), .line("means \(meaning.phrase)!")])
            pause = 4.5
        }
        Task {
            try? await Task.sleep(for: .seconds(pause))
            await nextQuestion()
        }
    }

    /// Learning path stop rules: sounds stop after 5 misses in a row,
    /// blending after 3 misses, real words stop at the first level with 3 misses.
    private func applyStopRules(after q: Question) {
        switch q {
        case .soundMatch where missesInARow >= 5:
            queue.removeAll { if case .soundMatch = $0 { true } else { false } }
            missesInARow = 0
        case .oralBlend where (score["blending"]?[1] ?? 0) - (score["blending"]?[0] ?? 0) >= 3:
            queue.removeAll { if case .oralBlend = $0 { true } else { false } }
        case .readWord(_, let level) where (levelResults[level] ?? []).filter({ !$0 }).count >= 2 && kind == .sparkleCheck:
            // this level is shaky: no harder levels
            queue.removeAll { if case .readWord(_, let l) = $0 { l >= level } else { false } }
        default: break
        }
    }

    private func finish() async {
        phase = .done
        question = nil
        #if DEBUG
        if kind != .warmUp(.rhymePop) && kind != .warmUp(.wingClaps) && kind != .warmUp(.onsetSlide) {
            Autopilot.after(6) { [services] in services.router.goHome() }
        }
        #endif
        switch kind {
        case .sparkleCheck:
            // start at the first level under 80%, never above stage 1's blending practice skipped
            let start = (1...5).first { level in
                let r = levelResults[level] ?? []
                return r.isEmpty || Double(r.filter { $0 }.count) / Double(r.count) < 0.8
            } ?? 6
            services.progress.completePlacement(startingStage: max(1, start))
            services.progress.record(Assessment(kind: .placement, date: .now, stage: max(1, start),
                                                parts: score, passed: true, shakySounds: shaky))
            passed = true
            resultLine = "Cutisie knows just where to start! Let's fly!"
            services.celebrateRoundComplete(game: .starCatch, line: resultLine)
            services.mascot.react(.levelUp)
        case .warmUp(let warmUp):
            let s = score[warmUpPart(warmUp)] ?? [0, 0]
            services.progress.recordWarmUp(warmUp, clean: s[0] == s[1] && s[1] > 0)
            passed = true
            resultLine = "Warmed up!"
            services.feedback.play(.star)
            services.mascot.react(.cheer)
            await services.voice.say("Great warm-up!")
            if services.router.inSession { services.router.advance() }
        case .skyTrial(let stage):
            let counted = ["words", "sentences", "heart", "unicorn"].compactMap { score[$0] }
            let right = counted.reduce(0) { $0 + $1[0] }, total = counted.reduce(0) { $0 + $1[1] }
            passed = total == 0 || Double(right) / Double(total) >= 0.8
            services.progress.record(Assessment(kind: .skyTrial, date: .now, stage: stage, parts: score, passed: passed))
            if passed {
                services.progress.passStageTrial(stage)
                services.progress.reachMilestone("stage-\(stage)")
                // learning path milestones 5, 8, 10, 11: vowels, digraphs, blends, magic e
                if let number = [2: 5, 3: 8, 4: 10, 5: 11][stage] {
                    services.celebration.playMilestone(number)
                }
                resultLine = "You did it! A rainbow bridge opens to a new world!"
                services.celebrateRoundComplete(game: .starCatch, line: resultLine)
                services.mascot.react(.levelUp)
            } else {
                resultLine = "Cutisie needs a little more wing sparkle. Let's practise and try again soon!"
                services.feedback.play(.star)
                services.mascot.react(.encourage)
                services.voice.announce(resultLine)
            }
        }
    }
}

private func warmUpPart(_ kind: WarmUpKind) -> String {
    switch kind {
    case .rhymePop: "rhyme"
    case .wingClaps: "claps"
    case .onsetSlide: "onset"
    }
}

extension CheckModel.Kind {
    var stage: Int { if case .skyTrial(let s) = self { s } else { 1 } }
}
