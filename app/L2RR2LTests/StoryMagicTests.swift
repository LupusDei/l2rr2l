import XCTest
@testable import L2RR2L

@MainActor
final class StoryMagicTests: XCTestCase {
    func testEveryStoryIsDecodableAtItsStage() {
        XCTAssertGreaterThanOrEqual(StoryContent.all.count, 20)
        for story in StoryContent.all {
            let taught = StoryContent.taught(upTo: story.stage)
            for line in story.pages + [story.check] {
                for token in StoryContent.tokens(line.text, stage: story.stage) where !token.isHeart {
                    XCTAssertEqual(token.word.graphemes.joined(), token.shown.lowercased(),
                                   "\(token.shown) tiles don't spell it in \"\(line.text)\"")
                    XCTAssertTrue(StoryContent.isDecodable(token.word, stage: story.stage, taught: taught),
                                  "\"\(token.shown)\" isn't decodable at stage \(story.stage): \"\(line.text)\"")
                }
            }
        }
    }

    func testEveryWordIsRecordedAndEverySceneWordIsInItsSentence() {
        for story in StoryContent.all {
            XCTAssertEqual(story.pages.count, 3, story.id)
            XCTAssertNotNil(story.check.silly, "\(story.id) check needs silly true/false")
            for line in story.pages + [story.check] {
                let words = Set(StoryContent.tokens(line.text, stage: story.stage).map(\.word.text))
                for w in words {
                    XCTAssertNotNil(Speaker.url(w, in: "Media/words"), "no recording for \"\(w)\" (\(story.id))")
                }
                let s = line.scene
                for w in [s.a, s.b, s.act, s.look].compactMap({ $0 }) {
                    XCTAssertTrue(words.contains(w), "scene word \(w) not in \"\(line.text)\"")
                }
                for w in [s.act, s.look].compactMap({ $0 }) {
                    XCTAssertTrue(StoryStage.knownActs.contains(w), "stage can't act out \(w)")
                }
                if let rel = s.rel { XCTAssertTrue(["on", "in", "has", "and"].contains(rel), rel) }
            }
        }
    }

    func testPickItChoicesDifferByOneTile() throws {
        for story in StoryContent.all {
            for line in story.pages {
                guard let gap = StoryContent.gap(for: line, stage: story.stage) else { continue }
                let target = StoryContent.tokens(line.text, stage: story.stage)[gap.index].word
                XCTAssertEqual(gap.choices.count, 3)
                XCTAssertEqual(gap.choices.filter { $0.text == target.text }.count, 1)
                for c in gap.choices where c.text != target.text {
                    XCTAssertEqual(zip(c.graphemes, target.graphemes).filter { $0 != $1 }.count, 1, "\(c.text) vs \(target.text)")
                    XCTAssertFalse(line.text.lowercased().contains(" \(c.text) "), "\(c.text) is already in \"\(line.text)\"")
                }
            }
        }
        // most pages can be a Pick It page
        let pages = StoryContent.all.flatMap { s in s.pages.map { (s, $0) } }
        let pickable = pages.filter { StoryContent.gap(for: $0.1, stage: $0.0.stage) != nil }
        XCTAssertGreaterThan(Double(pickable.count) / Double(pages.count), 0.8)
    }

    func testSillyChecksReallySwap() {
        let mat = StoryScene(a: "cat", rel: "on", b: "mat")
        XCTAssertEqual(mat.swapped, StoryScene(a: "mat", rel: "on", b: "cat"))
        XCTAssertEqual(mat.replacing("mat", with: "map").b, "map")
        XCTAssertNil(StoryScene(a: "cat", act: "nap").swapped)
    }

    func testLayoutPutsThingsOnTopAndInside() {
        let size = CGSize(width: 600, height: 400)
        let on = StageLayout.full(StoryScene(a: "cat", rel: "on", b: "bed"), in: size)
        let bed = on.first { $0.word == "bed" }!, cat = on.first { $0.word == "cat" }!
        XCTAssertLessThan(StageLayout.opaque(cat).midY, StageLayout.opaque(bed).midY, "the cat sits above the bed")
        let inside = StageLayout.full(StoryScene(a: "bug", rel: "in", b: "cup"), in: size)
        XCTAssertTrue(inside.contains { $0.word == "cup" && $0.clipTop != nil }, "the cup's front covers the bug")
        let squash = StageLayout.full(StoryScene(a: "bed", rel: "on", b: "cat"), in: size)
        XCTAssertTrue(squash.first { $0.word == "cat" }!.squashed, "a bed on a cat squashes it")
        for p in on + inside + squash {
            let r = StageLayout.opaque(p)
            XCTAssertGreaterThanOrEqual(r.minX, -1); XCTAssertLessThanOrEqual(r.maxX, size.width + 1)
            XCTAssertLessThanOrEqual(r.maxY, size.height + 1)
        }
    }

    func testStoryPickingPrefersUnreadAtHerStage() {
        for _ in 0..<20 {
            let s = StoryContent.pick(stage: 2, read: [])!
            XCTAssertEqual(s.stage, 2)
        }
        let stage1 = StoryContent.all.filter { $0.stage == 1 }.map(\.id)
        let next = StoryContent.pick(stage: 1, read: Array(stage1.dropLast()))
        XCTAssertEqual(next?.id, stage1.last)
        XCTAssertNotNil(StoryContent.pick(stage: 1, read: stage1))
    }

    func testModesStartWithPickThenMake() {
        let story = StoryContent.all[0]
        XCTAssertEqual(StoryMagicModel.modes(for: story, session: 0).prefix(2), [.pick, .make])
    }
}
