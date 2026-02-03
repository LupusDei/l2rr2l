import XCTest

/// Helper extensions for UI testing
extension XCUIApplication {
    /// Checks if running in UI testing mode
    var isUITesting: Bool {
        launchArguments.contains("UI_TESTING")
    }

    /// Waits for an element to exist and be hittable
    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

extension XCUIElement {
    /// Scrolls to make the element visible
    func scrollToVisible(in app: XCUIApplication, direction: ScrollDirection = .up) {
        var attempts = 0
        while !isHittable && attempts < 10 {
            switch direction {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            case .left:
                app.swipeLeft()
            case .right:
                app.swipeRight()
            }
            attempts += 1
        }
    }

    /// Clears text field content
    func clearText() {
        guard let text = value as? String, !text.isEmpty else { return }

        // Tap to focus
        tap()

        // Select all and delete
        let selectAllMenuItem = XCUIApplication().menuItems["Select All"]
        if selectAllMenuItem.waitForExistence(timeout: 1) {
            selectAllMenuItem.tap()
            typeText(XCUIKeyboardKey.delete.rawValue)
        } else {
            // Fallback: delete characters one by one
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count)
            typeText(deleteString)
        }
    }

    /// Types text with a slight delay between characters for reliability
    func typeTextSlowly(_ text: String, delay: TimeInterval = 0.05) {
        for character in text {
            typeText(String(character))
            Thread.sleep(forTimeInterval: delay)
        }
    }
}

enum ScrollDirection {
    case up
    case down
    case left
    case right
}

/// Test data for UI tests
enum UITestData {
    enum Auth {
        static let validEmail = "test@example.com"
        static let validPassword = "password123"
        static let invalidEmail = "invalid-email"
        static let invalidPassword = "123"
    }

    enum Onboarding {
        static let testName = "TestChild"
        static let emptyName = ""
    }
}
