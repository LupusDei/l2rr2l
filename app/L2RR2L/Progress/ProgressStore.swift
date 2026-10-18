import Foundation

/// Reads and writes `ProgressData`. All scoring comes from taps (no speech
/// recognition), so games report each answer with whether audio help was used
/// and how long the child took.
@MainActor
@Observable
final class ProgressStore {
    private(set) var data: ProgressData

    /// Stars needed to earn one treat for Cutisie.
    static let starsPerTreat = 5
    /// Treats fed to fill the mystery egg.
    static let treatsPerEgg = 5

    @ObservationIgnored private let fileURL: URL?
    @ObservationIgnored private let calendar = Calendar(identifier: .gregorian)
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    /// `fileURL: nil` keeps everything in memory (previews, tests).
    init(fileURL: URL? = ProgressStore.defaultURL) {
        self.fileURL = fileURL
        if let fileURL,
           let raw = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder.iso.decode(ProgressData.self, from: raw) {
            data = decoded
        } else {
            data = ProgressData()
        }
    }

    nonisolated static var defaultURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("progress.json")
    }

    // MARK: Answers & mastery

    /// Record one answer. Returns a sticker if this answer just mastered the word.
    @discardableResult
    func recordAnswer(game: GameID,
                      word: String?,
                      correct: Bool,
                      usedAudioHelp: Bool = false,
                      responseTime: TimeInterval? = nil,
                      errorTags: [String] = [],
                      now: Date = .now) -> Sticker? {
        mutate { d in
            d.daysPlayed.insert(dayKey(now))
            var stats = d.games[game.rawValue, default: GameStats()]
            stats.answers += 1
            if correct { stats.correct += 1 }
            stats.lastPlayed = now
            d.games[game.rawValue] = stats
            if !correct {
                for tag in errorTags { d.errorPatterns[tag, default: 0] += 1 }
            }
        }

        guard let word = word?.lowercased() else { return nil }
        var newSticker: Sticker?
        mutate { d in
            var record = d.words[word, default: WordRecord()]
            let wasMastered = record.isMastered
            record.attempts += 1
            record.lastSeen = now
            if correct {
                record.correct += 1
                let fast = (responseTime ?? .infinity) <= WordRecord.fastReadSeconds
                if !usedAudioHelp && fast { record.masteryDays.insert(dayKey(now)) }
                if !usedAudioHelp { record.knownDays.insert(dayKey(now)) }
                record.reviewIntervalDays = max(1, record.reviewIntervalDays * 2)
            } else {
                record.reviewIntervalDays = 0
            }
            record.nextReview = calendar.date(byAdding: .day, value: max(1, record.reviewIntervalDays), to: calendar.startOfDay(for: now))
            d.words[word] = record
            if !wasMastered && record.isMastered && !d.stickers.contains(where: { $0.word == word }) {
                let sticker = Sticker.forWord(word, at: now)
                d.stickers.append(sticker)
                newSticker = sticker
            }
        }
        return newSticker
    }

    /// Words due for spaced review, oldest-due first.
    func wordsDueForReview(now: Date = .now, limit: Int = 10) -> [String] {
        data.words
            .filter { ($0.value.nextReview ?? .distantFuture) <= now }
            .sorted { ($0.value.nextReview ?? now) < ($1.value.nextReview ?? now) }
            .prefix(limit)
            .map(\.key)
    }

    func masteredWords() -> [String] {
        data.words.filter { $0.value.isMastered }.map(\.key).sorted()
    }

    /// Most frequent error patterns, for choosing what to practise next.
    func topErrorPatterns(_ n: Int = 3) -> [(tag: String, count: Int)] {
        data.errorPatterns.sorted { $0.value > $1.value }.prefix(n).map { ($0.key, $0.value) }
    }

    // MARK: Skills

    /// Misses in a row on one skill before stepping down to a prerequisite.
    static let missesBeforeStepDown = 3

    /// Record an attempt on a skill. Returns a step-down when the reader is
    /// stuck and the graph has a prerequisite to go back to.
    @discardableResult
    func recordSkill(_ id: String, correct: Bool, graph: SkillGraph) -> StepDown? {
        var stuck = false
        mutate { d in
            var r = d.skills[id, default: SkillRecord()]
            r.attempts += 1
            if correct {
                r.correct += 1
                r.missesInARow = 0
                if r.state == .new { r.state = .learning }
            } else {
                r.missesInARow += 1
                if r.missesInARow >= Self.missesBeforeStepDown {
                    stuck = true
                    r.missesInARow = 0
                    r.stepDowns += 1
                }
            }
            d.skills[id] = r
        }
        return stuck ? graph.stepDown(from: id, records: data.skills) : nil
    }

    func setSkillState(_ id: String, _ state: SkillRecord.State) {
        mutate { $0.skills[id, default: SkillRecord()].state = state }
    }

    // MARK: Rewards

    /// Adds stars; every `starsPerTreat` stars also earns a treat for Cutisie.
    /// Returns how many new treats were earned.
    @discardableResult
    func awardStars(_ count: Int, game: GameID) -> Int {
        var newTreats = 0
        mutate { d in
            let before = d.stars / Self.starsPerTreat
            d.stars += count
            newTreats = d.stars / Self.starsPerTreat - before
            d.treats += newTreats
            d.games[game.rawValue, default: GameStats()].stars += count
        }
        return newTreats
    }

    /// Feed Cutisie one treat; each feed warms the mystery egg. Returns true
    /// when the egg is ready to hatch.
    @discardableResult
    func feedTreat() -> Bool {
        guard data.treats > 0 else { return false }
        var ready = false
        mutate { d in
            d.treats -= 1
            d.treatsFed += 1
            d.eggProgress += 1
            ready = d.eggProgress >= Self.treatsPerEgg
        }
        return ready
    }

    func hatchEgg(into creature: String) {
        mutate { d in
            d.eggProgress = 0
            d.hatched.append(creature)
        }
    }

    // MARK: Learning path

    /// Returns true the first time a milestone is reached.
    @discardableResult
    func reachMilestone(_ id: String) -> Bool {
        guard !data.milestones.contains(id) else { return false }
        mutate { $0.milestones.insert(id) }
        return true
    }

    func completePlacement(startingStage: Int) {
        mutate { d in
            d.placementDone = true
            d.stage = min(max(startingStage, 1), 8)
        }
    }

    func passStageTrial(_ stage: Int) {
        mutate { d in
            d.stageTrialsPassed.insert(stage)
            if stage >= d.stage { d.stage = min(stage + 1, 8) }
        }
    }

    func finishSession(game: GameID) {
        mutate { $0.games[game.rawValue, default: GameStats()].sessions += 1 }
    }

    func reset() { mutate { $0 = ProgressData() } }

    // MARK: Stages, assessments, sessions

    /// Words read correctly without help at least once (for milestones).
    var wordsReadAlone: Int { data.words.values.filter { !$0.knownDays.isEmpty }.count }

    /// Share of a stage's pictured words that are known (learning path:
    /// the next stage opens at 80% known plus a passed Sky Trial).
    func knownShare(of stage: Int) -> Double {
        let words = WordBank.items(in: stage).map(\.word.text)
        guard !words.isEmpty else { return 1 }
        let known = words.filter { data.words[$0]?.isKnown ?? false }.count
        return Double(known) / Double(words.count)
    }

    /// The Sky Trial for the current stage is ready when 80% of its words are known.
    var skyTrialReady: Bool {
        data.placementDone && !data.stageTrialsPassed.contains(data.stage) && knownShare(of: data.stage) >= 0.8
    }

    func record(_ assessment: Assessment) {
        mutate { $0.assessments.append(assessment) }
    }

    func recordWarmUp(_ kind: WarmUpKind, clean: Bool, now: Date = .now) {
        guard clean else { return }
        mutate { $0.warmUpDays[kind.rawValue, default: []].insert(dayKey(now)) }
    }

    /// Next warm-up in rotation; mastered ones (3 clean days) drop out.
    func nextWarmUp() -> WarmUpKind? {
        let open = WarmUpKind.allCases.filter { (data.warmUpDays[$0.rawValue]?.count ?? 0) < 3 }
        guard !open.isEmpty else { return nil }
        return open[data.sessionsCompleted % open.count]
    }

    /// The next sound in her world that hasn't had its "new thing" story yet.
    /// Placement puts her past earlier worlds, so only the current one counts.
    func nextNewSound() -> String? {
        guard let stage = Curriculum.shared.stage(max(data.stage, 1)) else { return nil }
        return stage.graphemes.first { !data.introduced.contains($0) && NewThing.clipName(for: $0) != nil }
    }

    func markIntroduced(_ grapheme: String) {
        mutate { $0.introduced.insert(grapheme) }
    }

    /// Ends a session: always grants one collectible. Returns it.
    @discardableResult
    func completeSession(now: Date = .now) -> String {
        var prize = ""
        mutate { d in
            d.sessionsCompleted += 1
            let owned = Set(d.collectibles)
            let next = Collectibles.pool.first { !owned.contains($0) } ?? Collectibles.pool.randomElement()!
            d.collectibles.append(next)
            prize = next
        }
        return prize
    }

    // MARK: Persistence

    private func mutate(_ change: (inout ProgressData) -> Void) {
        change(&data)
        scheduleSave()
    }

    private func scheduleSave() {
        guard let fileURL else { return }
        saveTask?.cancel()
        let snapshot = data
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let raw = try? JSONEncoder.iso.encode(snapshot) else { return }
            try? raw.write(to: fileURL, options: .atomic)
        }
    }

    /// Writes immediately (call when the app goes to background).
    func saveNow() {
        guard let fileURL, let raw = try? JSONEncoder.iso.encode(data) else { return }
        try? raw.write(to: fileURL, options: .atomic)
    }

    private func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}

private extension JSONEncoder {
    static let iso: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}

private extension JSONDecoder {
    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
