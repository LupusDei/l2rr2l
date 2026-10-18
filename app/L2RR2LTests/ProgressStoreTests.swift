import XCTest
@testable import L2RR2L

@MainActor
final class ProgressStoreTests: XCTestCase {
    private func day(_ n: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: n, hour: 10))!
    }

    func testWordMasteredAfterThreeSeparateFastUnaidedDays() {
        let store = ProgressStore(fileURL: nil)
        XCTAssertNil(store.recordAnswer(game: .starCatch, word: "cat", correct: true, responseTime: 1.5, now: day(1)))
        // Same day again doesn't count twice.
        XCTAssertNil(store.recordAnswer(game: .starCatch, word: "cat", correct: true, responseTime: 1.5, now: day(1)))
        XCTAssertNil(store.recordAnswer(game: .starCatch, word: "cat", correct: true, responseTime: 1.5, now: day(2)))
        let sticker = store.recordAnswer(game: .starCatch, word: "cat", correct: true, responseTime: 2, now: day(4))
        XCTAssertEqual(sticker?.word, "cat")
        XCTAssertEqual(store.masteredWords(), ["cat"])
        XCTAssertEqual(store.data.stickers.count, 1)
    }

    func testSlowOrAudioAidedReadsDontCountTowardMastery() {
        let store = ProgressStore(fileURL: nil)
        store.recordAnswer(game: .starCatch, word: "sun", correct: true, usedAudioHelp: true, responseTime: 1, now: day(1))
        store.recordAnswer(game: .starCatch, word: "sun", correct: true, responseTime: 8, now: day(2))
        XCTAssertEqual(store.data.words["sun"]?.masteryDays.count, 0)
        XCTAssertEqual(store.data.words["sun"]?.correct, 2)
    }

    func testMissesTrackErrorPatternsAndResetReview() {
        let store = ProgressStore(fileURL: nil)
        store.recordAnswer(game: .wordMachine, word: "bed", correct: false, errorTags: ["reversal:b-d"], now: day(1))
        store.recordAnswer(game: .wordMachine, word: "dog", correct: false, errorTags: ["reversal:b-d"], now: day(1))
        XCTAssertEqual(store.topErrorPatterns().first?.tag, "reversal:b-d")
        XCTAssertEqual(store.topErrorPatterns().first?.count, 2)
        XCTAssertEqual(Set(store.wordsDueForReview(now: day(3))), ["bed", "dog"])
    }

    func testStarsEarnTreatsAndTreatsHatchEgg() {
        let store = ProgressStore(fileURL: nil)
        XCTAssertEqual(store.awardStars(4, game: .stretchyBlend), 0)
        XCTAssertEqual(store.awardStars(7, game: .stretchyBlend), 2)
        XCTAssertEqual(store.data.treats, 2)
        var ready = false
        for _ in 0..<ProgressStore.treatsPerEgg { ready = store.feedTreat() || ready }
        XCTAssertFalse(ready, "only 2 treats available")
        XCTAssertEqual(store.data.eggProgress, 2)
    }

    func testPersistsToDisk() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ProgressStore(fileURL: url)
        store.awardStars(3, game: .starCatch)
        store.reachMilestone("first-word")
        store.saveNow()
        let reloaded = ProgressStore(fileURL: url)
        XCTAssertEqual(reloaded.data.stars, 3)
        XCTAssertTrue(reloaded.data.milestones.contains("first-word"))
    }
}

@MainActor
final class SkillGraphTests: XCTestCase {
    func testStuckSkillStepsDownToWeakestPrerequisiteWithBridge() {
        let graph = SkillGraph([
            Skill(id: "sounds-m-s-a", stage: 0),
            Skill(id: "oral-blend", stage: 0),
            Skill(id: "blend-cvc", stage: 1, prerequisites: ["sounds-m-s-a", "oral-blend"], bridge: "stretchy-blend:listen"),
        ])
        let store = ProgressStore(fileURL: nil)
        store.setSkillState("sounds-m-s-a", .known)
        XCTAssertNil(store.recordSkill("blend-cvc", correct: false, graph: graph))
        XCTAssertNil(store.recordSkill("blend-cvc", correct: false, graph: graph))
        let step = store.recordSkill("blend-cvc", correct: false, graph: graph)
        XCTAssertEqual(step, StepDown(from: "blend-cvc", prerequisite: "oral-blend", bridge: "stretchy-blend:listen"))
        XCTAssertEqual(store.data.skills["blend-cvc"]?.stepDowns, 1)
    }
}

@MainActor
final class CurriculumTests: XCTestCase {
    func testCurriculumLoadsAllStagesWithPlayableWords() {
        let c = Curriculum.shared
        XCTAssertEqual(c.stages.map(\.id), Array(0...7))
        for stage in 1...6 {
            XCTAssertGreaterThanOrEqual(WordBank.items(in: stage).count, 10, "stage \(stage) needs picture words")
            XCTAssertFalse(WordBank.chains(for: stage).isEmpty, "stage \(stage) needs chains")
        }
    }

    func testMagicESoundsAreLongAndSilent() {
        let cape = Curriculum.shared.stage(5)!.words.first { $0.text == "cape" }!
        XCTAssertEqual(cape.soundKeys, ["c", "a_e", "p", ""])
        XCTAssertEqual(cape.spokenSounds, ["c", "a_e", "p"])
    }

    func testPlannerFillsRoundsFromCurrentStage() {
        let store = ProgressStore(fileURL: nil)
        store.completePlacement(startingStage: 2)
        let planner = SessionPlanner(progress: store)
        let items = planner.pictureItems(6)
        XCTAssertEqual(items.count, 6)
        XCTAssertTrue(items.allSatisfy { ($0.word.stage ?? 0) <= 2 })
        XCTAssertNotNil(planner.chain())
        let catches = planner.catchItems(6)
        XCTAssertGreaterThanOrEqual(catches.count, 6)
    }

    func testSkyTrialOpensAtEightyPercentKnown() {
        let store = ProgressStore(fileURL: nil)
        store.completePlacement(startingStage: 1)
        XCTAssertFalse(store.skyTrialReady)
        let words = WordBank.items(in: 1).map(\.word.text)
        let cal = Calendar(identifier: .gregorian)
        for day in 1...2 {
            let date = cal.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 9))!
            for w in words { store.recordAnswer(game: .starCatch, word: w, correct: true, responseTime: 5, now: date) }
        }
        XCTAssertTrue(store.skyTrialReady)
        store.passStageTrial(1)
        XCTAssertEqual(store.data.stage, 2)
    }

    func testOldSaveFilesStillLoad() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        try #"{"stars": 7, "words": {"cat": {"attempts": 2, "correct": 2, "masteryDays": []}}}"#.write(to: url, atomically: true, encoding: .utf8)
        let store = ProgressStore(fileURL: url)
        XCTAssertEqual(store.data.stars, 7)
        XCTAssertEqual(store.data.words["cat"]?.correct, 2)
        XCTAssertEqual(store.data.collectibles, [])
    }
}

@MainActor
final class WarmUpTests: XCTestCase {
    func testWarmUpContentAndQuestions() {
        XCTAssertNotNil(Curriculum.shared.warmups)
        for kind in WarmUpKind.allCases {
            XCTAssertEqual(CheckModel.warmUpQuestions(kind, count: 4).count, 4, "\(kind)")
        }
        let sparkle = CheckModel.sparkleQuestions()
        XCTAssertTrue(sparkle.contains { if case .rhyme = $0 { true } else { false } })
        XCTAssertTrue(sparkle.contains { if case .claps = $0 { true } else { false } })
    }

    func testWarmUpsRotateAndDropOutAfterThreeCleanDays() {
        let store = ProgressStore(fileURL: nil)
        XCTAssertNotNil(store.nextWarmUp())
        let cal = Calendar(identifier: .gregorian)
        for day in 1...3 {
            store.recordWarmUp(.rhymePop, clean: true, now: cal.date(from: DateComponents(year: 2026, month: 10, day: day))!)
        }
        for _ in 0..<3 {
            XCTAssertNotEqual(store.nextWarmUp(), .rhymePop)
            store.completeSession()
        }
    }
}
