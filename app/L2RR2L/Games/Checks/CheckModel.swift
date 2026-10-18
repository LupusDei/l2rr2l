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
    enum Kind: Equatable { case sparkleCheck, skyTrial(stage: Int) }

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

        var part: String {
            switch self {
            case .soundMatch: "sounds"
            case .oralBlend: "blending"
            case .readWord: "words"
            case .heart: "heart"
            case .unicorn: "unicorn"
            case .sentence: "sentences"
            }
        }
    }

    enum Phase: Equatable { case intro, asking, answered, done }

    let kind: Kind
    private(set) var question: Question?
    private(set) var phase: Phase = .intro
    private(set) var choiceOrder: [String] = []
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
        queue = kind == .sparkleCheck ? Self.sparkleQuestions() : Self.trialQuestions(stage: kind.stage)
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
        return q
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
            default: nil
            }
        }.flatMap { $0 }
        await services.phonemes.prepare(all)
        services.mascot.react(.hello)
        switch kind {
        case .sparkleCheck:
            await services.voice.say("Let's play Cutisie's Sparkle Check! There are no wrong answers. Every answer makes a sparkle.")
        case .skyTrial(let stage):
            let name = Curriculum.shared.stage(stage)?.name ?? "this world"
            await services.voice.say("It's a Sky Trial! Help Cutisie fly past \(name)!")
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
        }
        await prompt(q)
        shownAt = .now
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
            services.mascot.react(.sing)
            await services.voice.say("A unicorn word! Read it out loud.")
        case .readWord, .sentence:
            break
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
        if let q = question, case .unicorn = q {
            services.sounds.playPack("giggle")
            services.mascot.react(.sing)
        }
        Task {
            try? await Task.sleep(for: .seconds(0.9))
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
            resultLine = "Cutisie knows just where to start! Let's fly to \(Curriculum.shared.stage(max(1, start))?.name ?? "the sky")!"
            services.celebrateRoundComplete(game: .starCatch, line: resultLine)
            services.mascot.react(.levelUp)
        case .skyTrial(let stage):
            let counted = ["words", "sentences", "heart", "unicorn"].compactMap { score[$0] }
            let right = counted.reduce(0) { $0 + $1[0] }, total = counted.reduce(0) { $0 + $1[1] }
            passed = total == 0 || Double(right) / Double(total) >= 0.8
            services.progress.record(Assessment(kind: .skyTrial, date: .now, stage: stage, parts: score, passed: passed))
            if passed {
                services.progress.passStageTrial(stage)
                services.progress.reachMilestone("stage-\(stage)")
                let next = Curriculum.shared.stage(stage + 1)?.name ?? "a brand new sky"
                resultLine = "You did it! A rainbow bridge opens to \(next)!"
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

extension CheckModel.Kind {
    var stage: Int { if case .skyTrial(let s) = self { s } else { 1 } }
}
