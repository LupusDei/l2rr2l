import XCTest

/// Plays Word Machine through the real screen, the way a child taps:
/// a full chain twice in a row, then three chains back to back.
/// The app is launched with -uitest, which opens Word Machine directly and
/// exposes the current answer to the test only (never drawn on screen).
final class WordMachineUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(chain: Int) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-uitestChain", "\(chain)"]
        app.launch()
        return app
    }

    /// Builds every word of the chain by tapping tiles and boxes, then the lever.
    private func playChain(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let answer = app.descendants(matching: .any)["answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 20), file: file, line: line)
        var words = 0
        while words < 8 {
            // wait until it's her turn to build, or the chain is done
            let deadline = Date().addingTimeInterval(40)
            while Date() < deadline {
                let v = answer.value as? String ?? ""
                if v == "scene" || (!v.isEmpty && !v.contains("idle") && !v.contains("running") && !v.contains("reveal")
                                    && !v.contains("nextWord") && !v.contains("complete")) { break }
                Thread.sleep(forTimeInterval: 0.3)
            }
            let value = answer.value as? String ?? ""
            if value == "scene" { return }
            let letters = value.split(separator: " ").map(String.init)
            XCTAssertFalse(letters.isEmpty, "no word to build (state \(value))", file: file, line: line)
            for (i, letter) in letters.enumerated() {
                let box = app.descendants(matching: .any)["box-\(i)"]
                XCTAssertTrue(box.waitForExistence(timeout: 5), file: file, line: line)
                let tile = app.descendants(matching: .any)["tile-\(letter)"]
                if tile.exists && tile.isHittable {
                    tile.tap()
                    // in a change step the tile is picked up; tap the box to drop it
                    Thread.sleep(forTimeInterval: 0.25)
                    if (answer.value as? String ?? "") == value { box.tap() }
                }
                Thread.sleep(forTimeInterval: 0.35)
            }
            let lever = app.descendants(matching: .any)["lever"]
            let ready = Date().addingTimeInterval(10)
            while Date() < ready, (answer.value as? String ?? "") != "complete" { Thread.sleep(forTimeInterval: 0.2) }
            XCTAssertEqual(answer.value as? String, "complete", "word \(letters.joined()) didn't complete", file: file, line: line)
            lever.tap()
            words += 1
        }
        XCTFail("chain never finished", file: file, line: line)
    }

    func testFullChainTwiceInARow() {
        let app = launch(chain: 0)
        playChain(app)
        app.buttons["playAgain"].tap()
        // play again moves to the next chain; the test plays it through too
        playChain(app)
    }

    func testThreeChainsBackToBack() {
        let app = launch(chain: 0)
        playChain(app)
        app.buttons["playAgain"].tap()
        playChain(app)
        app.buttons["playAgain"].tap()
        playChain(app)
    }
}
