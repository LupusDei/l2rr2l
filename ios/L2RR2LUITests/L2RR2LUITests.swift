import XCTest

final class L2RR2LUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
    }
}
