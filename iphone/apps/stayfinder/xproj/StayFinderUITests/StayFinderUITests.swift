import XCTest

final class StayFinderUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSearchPanelAppliesDestination() {
        launchApp(arguments: ["-bnb-ui-test-open-search"])

        let destinationField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(destinationField.waitForExistence(timeout: 5))
        destinationField.tap()
        destinationField.typeText("Seoul")
        destinationField.typeText("\n")

        let applyButton = element("bnb.search.apply")
        XCTAssertTrue(applyButton.waitForExistence(timeout: 5))
        tapElement(applyButton)

        let searchBar = element("bnb.explore.searchBar")
        XCTAssertTrue(searchBar.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(on: searchBar, containing: "Seoul · Any week · 1 guest"))

        let seoulListing = element("stay-seoul-hanok")
        XCTAssertTrue(seoulListing.waitForExistence(timeout: 5))
    }

    func testReserveButtonOpensBookingScreen() {
        launchApp(arguments: ["-bnb-ui-test-open-listing", "stay-soma"])

        let reserveButton = element("bnb.detail.reserve")
        XCTAssertTrue(reserveButton.waitForExistence(timeout: 5))
        tapElement(reserveButton)

        let bookingScreen = element("bnb.booking.screen")
        XCTAssertTrue(bookingScreen.waitForExistence(timeout: 5))
        XCTAssertTrue(element("bnb.booking.continue").waitForExistence(timeout: 5))
    }

    func testBookingFlowCreatesUpcomingTrip() {
        launchApp(arguments: ["-bnb-ui-test-open-checkout", "stay-beach"])

        let confirmSwitch = app.switches.element(boundBy: 0)
        XCTAssertTrue(confirmSwitch.waitForExistence(timeout: 5))
        if let switchValue = confirmSwitch.value as? String, switchValue == "0" || switchValue == "Off" {
            confirmSwitch.tap()
        }

        let confirmButton = app.buttons["Confirm Booking"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        tapElement(confirmButton)

        XCTAssertTrue(element("bnb.trips.upcomingHeader").waitForExistence(timeout: 5))
    }

    func testMessagesFlowSendsMessage() {
        launchApp(arguments: ["-bnb-ui-test-open-conversation", "stay-soma"])

        let input = app.textFields["Type a message"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("Checking in from UI test.")
        input.typeText("\n")

        let sendButton = app.buttons["Send"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        tapElement(sendButton)

        let transcript = element("bnb.chat.transcriptSummary")
        XCTAssertTrue(transcript.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(on: transcript, containing: "Checking in from UI test."))
    }

    func testPastTripsScreenLoads() {
        launchApp(arguments: ["-bnb-ui-test-open-past-trips"])
        XCTAssertTrue(app.navigationBars["Past trips"].waitForExistence(timeout: 5))
    }

    func testNotificationsFlowOpensDestination() {
        launchApp(arguments: ["-bnb-ui-test-open-notifications"])

        let notification = element("bnb.notifications.0")
        XCTAssertTrue(notification.waitForExistence(timeout: 5))
        tapElement(notification)

        let chatScreen = element("bnb.chat.screen")
        XCTAssertTrue(chatScreen.waitForExistence(timeout: 5))
    }

    func testHostingFlowOpensSampleListing() {
        launchApp(arguments: ["-bnb-ui-test-open-hosting"])

        let sampleButton = element("bnb.hosting.sampleListing")
        XCTAssertTrue(sampleButton.waitForExistence(timeout: 5))
        tapElement(sampleButton)

        let detailScreen = element("bnb.detail.screen")
        XCTAssertTrue(detailScreen.waitForExistence(timeout: 5))
    }

    private func launchApp(arguments: [String]) {
        app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
    }

    private func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
            return
        }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func element(_ identifier: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func waitForLabel(on element: XCUIElement, containing text: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
