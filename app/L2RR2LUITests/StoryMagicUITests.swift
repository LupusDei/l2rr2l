import XCTest

/// Plays Story Magic through the real screen like a five-year-old: a wrong
/// word cloud first, the help wing, a wrong word in the sentence, tapping a
/// placed word to send it back, then the right answers; the meaning check;
/// the story book; Play Again. Launched with -uitest -uitestGame storyMagic,
/// which exposes the game's state to the test only (never drawn).
final class StoryMagicUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }
    override func tearDown() { XCUIDevice.shared.orientation = .portrait }

    private struct State {
        let phase: String, busy: Bool, page: Int, right: String, wrong: String
        init(_ raw: String) {
            let f = raw.split(separator: " ").map(String.init)
            phase = f.first ?? ""
            busy = f.count > 1 && f[1] == "1"
            page = f.count > 2 ? Int(f[2]) ?? 0 : 0
            right = f.count > 3 ? f[3] : "-"
            wrong = f.count > 4 ? f[4] : "-"
        }
    }

    private func launch(_ orientation: UIDeviceOrientation, story: String) -> XCUIApplication {
        XCUIDevice.shared.orientation = orientation
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-uitestGame", "storyMagic", "-uitestStory", story]
        app.launch()
        return app
    }

    private func state(_ app: XCUIApplication) -> State {
        State(app.descendants(matching: .any)["storyState"].value as? String ?? "")
    }

    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func waitIdle(_ app: XCUIApplication, _ seconds: Double = 15) {
        let end = Date().addingTimeInterval(seconds)
        Thread.sleep(forTimeInterval: 0.3)
        while Date() < end, state(app).busy { Thread.sleep(forTimeInterval: 0.2) }
    }

    private func play(_ app: XCUIApplication, label: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(el(app, "storyState").waitForExistence(timeout: 20), file: file, line: line)
        var triedWrongPick = false, triedWrongMake = false, triedHelp = false, judged = false
        var seen: Set<String> = []
        let deadline = Date().addingTimeInterval(400)
        while Date() < deadline {
            let s = state(app)
            if s.phase == "roundDone" { snap("\(label) round done"); return }
            let key = "\(s.phase) \(s.page)"
            if !seen.contains(key) { seen.insert(key); snap("\(label) \(key)") }
            guard !s.busy else { Thread.sleep(forTimeInterval: 0.3); continue }
            switch s.phase {
            case "pick":
                if !triedWrongPick, s.wrong != "-" {
                    triedWrongPick = true
                    el(app, "choice-\(s.wrong)").tap()
                    Thread.sleep(forTimeInterval: 0.8)
                    snap("\(label) silly pick")
                    waitIdle(app)
                    XCTAssertEqual(state(app).phase, "pick", "a wrong word was accepted", file: file, line: line)
                } else if !triedHelp {
                    triedHelp = true
                    el(app, "help").tap()
                    waitIdle(app, 20)
                    XCTAssertEqual(state(app).phase, "pick", "help moved on by itself", file: file, line: line)
                } else {
                    el(app, "choice-\(s.right)").tap()
                    waitIdle(app, 25)
                }
            case "make":
                if !triedWrongMake, s.wrong != "-" {
                    // a wrong word into the sentence, then tap it to send it back
                    triedWrongMake = true
                    el(app, "tile-\(s.wrong)").tap()
                    Thread.sleep(forTimeInterval: 0.8)
                    snap("\(label) wrong word placed")
                    let tileGone = !el(app, "tile-\(s.wrong)").exists
                    XCTAssertTrue(tileGone, "the tapped word didn't leave its cloud", file: file, line: line)
                    tapPlacedBack(app, token: s.wrong)
                    Thread.sleep(forTimeInterval: 0.6)
                    XCTAssertTrue(el(app, "tile-\(s.wrong)").waitForExistence(timeout: 3), "tapping a placed word didn't send it back", file: file, line: line)
                } else if s.right != "-" {
                    el(app, "tile-\(s.right)").tap()
                    Thread.sleep(forTimeInterval: 0.6)
                    waitIdle(app, 25)
                } else {
                    Thread.sleep(forTimeInterval: 0.3)
                }
            case "judge":
                if !judged {
                    judged = true
                    el(app, "judge-\(s.right)").tap()
                    Thread.sleep(forTimeInterval: 1)
                    snap("\(label) acted out")
                }
                Thread.sleep(forTimeInterval: 0.4)
            default:
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
        XCTFail("story never finished (state \(state(app)))", file: file, line: line)
    }

    /// Taps the slot holding the given token (slots are labelled with their word).
    private func tapPlacedBack(_ app: XCUIApplication, token: String) {
        let slots = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'slot-'"))
        for i in 0..<slots.count {
            let s = slots.element(boundBy: i)
            if s.exists && s.isHittable {
                s.tap()
                Thread.sleep(forTimeInterval: 0.5)
                if el(app, "tile-\(token)").exists { return }
            }
        }
    }

    func testWholeStoryThenPlayAgain() {
        let app = launch(.portrait, story: "cat-nap")
        play(app, label: "portrait")
        let again = app.buttons["playAgain"]
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        again.tap()
        let next = Date().addingTimeInterval(20)
        while Date() < next, state(app).phase != "pick" { Thread.sleep(forTimeInterval: 0.3) }
        XCTAssertEqual(state(app).phase, "pick")
        snap("again first page")
    }

    func testWholeStoryLandscape() {
        let app = launch(.landscapeLeft, story: "fox-box")
        play(app, label: "landscape")
    }
}
