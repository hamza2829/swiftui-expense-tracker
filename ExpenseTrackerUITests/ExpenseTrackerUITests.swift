import XCTest

final class ExpenseTrackerUITests: XCTestCase {
    @MainActor
    func testTransactionListAppears() {
        let app = XCUIApplication()
        // Use the in-memory mock API so the test does not depend on a server.
        app.launchArguments = ["-useMockAPI"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Expenses"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Groceries"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Running shoes"].exists)
    }
}
