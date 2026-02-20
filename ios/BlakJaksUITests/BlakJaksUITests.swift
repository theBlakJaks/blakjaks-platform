import XCTest

final class BlakJaksUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testAgeGateAppearsOnFirstLaunch() {
        let ageQuestion = app.staticTexts["Are you 21 or older?"]
        XCTAssertTrue(ageQuestion.waitForExistence(timeout: 5))
    }

    func testAgeGateYesButtonProceedsToApp() {
        let yesButton = app.buttons["Yes, I am 21+"]
        if yesButton.waitForExistence(timeout: 5) {
            yesButton.tap()
            let welcomeText = app.staticTexts["Welcome to BlakJaks"]
            XCTAssertTrue(welcomeText.waitForExistence(timeout: 3))
        }
    }
}
