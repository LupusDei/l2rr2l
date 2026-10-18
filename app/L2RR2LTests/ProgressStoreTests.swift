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
