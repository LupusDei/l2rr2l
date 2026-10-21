import XCTest
@testable import L2RR2L

@MainActor
final class ReadAlongTests: XCTestCase {
    func testEverySentenceIsDecodableAtItsStage() {
        XCTAssertFalse(ReadAlongContent.all.isEmpty)
        let stages = Curriculum.shared.stages
        for sentence in ReadAlongContent.all {
            var taught: Set<String> = ["ck", "ff", "ll", "ss"]
            for stage in stages where stage.id <= sentence.stage { taught.formUnion(stage.graphemes) }
            for token in sentence.tokens where !token.isHeart {
                let letters = token.word.graphemes.joined()
                XCTAssertEqual(letters, token.shown.lowercased(), "\(token.shown) tiles don't spell it in \"\(sentence.text)\"")
                for (g, sound) in zip(token.word.graphemes, token.word.soundKeys) where !sound.isEmpty {
                    let ok = taught.contains(g) || taught.contains(sound) || (sound.hasSuffix("_e") && taught.contains(sound))
                        || (sound == "ow_cow" && taught.contains("ow")) || (g == "s" && sound == "z")
                    XCTAssertTrue(ok, "\"\(token.shown)\" needs \(g) before stage \(sentence.stage): \"\(sentence.text)\"")
                }
            }
        }
    }

    func testEverySoundHasAMouthAndARecording() {
        let sounds = Set(ReadAlongContent.all.flatMap { $0.tokens.flatMap(\.word.soundKeys) }).subtracting([""])
        for sound in sounds {
            XCTAssertNotNil(Bundle.main.url(forResource: sound, withExtension: "wav", subdirectory: "Media/phonemes"),
                            "no recording for /\(sound)/")
        }
        XCTAssertEqual(Viseme.of("m"), .closed)
        XCTAssertEqual(Viseme.of("oo"), .round)
        XCTAssertEqual(Viseme.of("sh"), .pucker)
        XCTAssertEqual(Viseme.of("f"), .teeth)
        XCTAssertEqual(Viseme.of("a"), .open)
    }

    func testPiecesKeepCapitalsAndSplitTeams() {
        let ship = Word("ship", nil, graphemes: ["sh", "i", "p"])
        let token = ReadToken(id: 0, shown: "Ship", trailing: ".", word: ship, isHeart: false)
        XCTAssertEqual(token.pieces, ["Sh", "i", "p"])
    }

    func testHeartWordsAreMarked() {
        let sentence = ReadAlongContent.all.first { $0.text == "The cat is sad." }
        XCTAssertEqual(sentence?.tokens.map(\.isHeart), [true, false, true, false])
        XCTAssertEqual(sentence?.tokens.last?.trailing, ".")
    }

    func testRoundStaysAtOrBelowStage() {
        for stage in 1...6 {
            let round = ReadAlongContent.round(stage: stage, count: 4)
            XCTAssertEqual(round.count, 4)
            XCTAssertTrue(round.allSatisfy { $0.stage <= stage })
        }
    }

    func testMouthTrackFollowsLoudness() {
        // silence, a voiced stretch, silence: closed at both ends, open inside
        let levels = [0, 0, 0.5, 1, 1, 0.8, 0.6, 0, 0]
        let track = LipSync.track(sounds: ["c", "a", "t"], levels: levels)
        XCTAssertEqual(track.first?.viseme, .closed)
        XCTAssertEqual(track.last?.viseme, .closed)
        XCTAssertTrue(track.contains { $0.viseme == .open })
    }

    func testNearMissDiffersByOneTile() throws {
        let cat = try XCTUnwrap(ReadAlongContent.curriculumWords["cat"])
        for _ in 0..<10 {
            let miss = try XCTUnwrap(ReadAlongContent.nearMiss(for: cat))
            XCTAssertEqual(zip(miss.graphemes, cat.graphemes).filter { $0 != $1 }.count, 1)
        }
    }
}
