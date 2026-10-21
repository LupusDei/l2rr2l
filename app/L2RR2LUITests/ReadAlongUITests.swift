import XCTest

/// Plays Read Along through the real screen, the way a child taps: a wrong
/// word first, Cutisie for help, then every word in order; in Fix It a wrong
/// guess and then the word Cutisie misread. A full round, then Play Again.
/// The app is launched with -uitest -uitestGame readAlong, which exposes the
/// game's state to the test only (never drawn on screen). Screenshots of each
/// moment are kept in the test results.
final class ReadAlongUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    private struct State {
        let phase: String
        let busy: Bool
        let next: Int?
        let misread: Int?
        let count: Int
        let index: Int

        init(_ raw: String) {
            let f = raw.split(separator: " ").map(String.init)
            phase = f.first ?? ""
            busy = f.count > 1 && f[1] == "1"
            next = f.count > 2 ? Int(f[2]) : nil
            misread = f.count > 3 ? Int(f[3]) : nil
            count = f.count > 4 ? Int(f[4]) ?? 0 : 0
            index = f.count > 5 ? Int(f[5]) ?? 0 : 0
        }
    }

    private func launch(_ orientation: UIDeviceOrientation) -> XCUIApplication {
        XCUIDevice.shared.orientation = orientation
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-uitestGame", "readAlong"]
        app.launch()
        return app
    }

    private func state(_ app: XCUIApplication) -> State {
        State(app.descendants(matching: .any)["readState"].value as? String ?? "")
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func word(_ app: XCUIApplication, _ i: Int) -> XCUIElement {
        app.descendants(matching: .any)["word-\(i)"].firstMatch
    }

    /// Plays sentences until the round is done (or `sentences` are read).
    private func play(_ app: XCUIApplication, label: String, sentences: Int = .max,
                      file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.descendants(matching: .any)["readState"].waitForExistence(timeout: 20), file: file, line: line)
        var askedForHelp = false, triedWrong = false, triedWrongFix = false
        var seen: Set<String> = []
        let start = state(app).index
        let deadline = Date().addingTimeInterval(400)
        while Date() < deadline {
            let s = state(app)
            if s.phase == "roundDone" { snap("\(label) round done"); return }
            if s.index - start >= sentences { return }
            if !seen.contains(s.phase) { seen.insert(s.phase); snap("\(label) \(s.phase)") }
            switch s.phase {
            case "yourTurn" where !s.busy && s.next != nil:
                let next = s.next!
                if !triedWrong, s.count > 1, next == 0 {
                    // a five-year-old taps the last word first: nothing happens but a wiggle
                    triedWrong = true
                    word(app, s.count - 1).tap()
                    Thread.sleep(forTimeInterval: 0.6)
                    XCTAssertEqual(state(app).next, next, "a word out of order was accepted", file: file, line: line)
                } else if !askedForHelp {
                    // stuck: tap Cutisie and she sounds the word out
                    askedForHelp = true
                    app.descendants(matching: .any)["cutisie"].firstMatch.tap()
                    let helping = Date().addingTimeInterval(4)
                    while Date() < helping, !state(app).busy { Thread.sleep(forTimeInterval: 0.1) }
                    snap("\(label) Cutisie helps")
                    let done = Date().addingTimeInterval(15)
                    while Date() < done, state(app).busy { Thread.sleep(forTimeInterval: 0.2) }
                    XCTAssertEqual(state(app).next, next, "help moved on by itself", file: file, line: line)
                } else {
                    XCTAssertTrue(word(app, next).isHittable, "word \(next) can't be tapped", file: file, line: line)
                    word(app, next).tap()
                    Thread.sleep(forTimeInterval: 0.7)
                }
            case "fixIt" where !s.busy && s.misread != nil:
                let wrong = s.misread!
                if !triedWrongFix, let other = (0..<s.count).first(where: { $0 != wrong }) {
                    triedWrongFix = true
                    word(app, other).tap()
                    Thread.sleep(forTimeInterval: 0.5)
                    let back = Date().addingTimeInterval(10)
                    while Date() < back, state(app).busy { Thread.sleep(forTimeInterval: 0.2) }
                    XCTAssertEqual(state(app).phase, "fixIt", "a right word counted as the fix", file: file, line: line)
                } else {
                    word(app, wrong).tap()
                    snap("\(label) fixed it")
                    Thread.sleep(forTimeInterval: 1)
                }
            default:
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
        XCTFail("round never finished (state \(state(app)))", file: file, line: line)
    }

    func testFullRoundThenPlayAgain() {
        let app = launch(.portrait)
        play(app, label: "portrait")
        let again = app.buttons["playAgain"]
        XCTAssertTrue(again.waitForExistence(timeout: 5))
        again.tap()
        play(app, label: "again", sentences: 1)
    }

    func testFullRoundLandscape() {
        let app = launch(.landscapeLeft)
        play(app, label: "landscape")
    }
}
