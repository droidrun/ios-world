import XCTest

final class MessagesUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testOpenChatInfoFromSeededChat() {
        let mayaRow = app.buttons["Maya Patel"]
        XCTAssertTrue(mayaRow.waitForExistence(timeout: 2))
        mayaRow.tap()

        XCTAssertTrue(app.textFields["chat_compose_field"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["tab_chats"].exists)

        let infoButton = app.buttons["chat_info_button"]
        XCTAssertTrue(infoButton.waitForExistence(timeout: 2))
        infoButton.tap()

        XCTAssertTrue(app.staticTexts["Shared media"].waitForExistence(timeout: 2))
    }

    func testComposeAndSendMessageInSeededChat() {
        let mayaRow = app.buttons["Maya Patel"]
        XCTAssertTrue(mayaRow.waitForExistence(timeout: 2))
        mayaRow.tap()

        let composeField = app.textFields["chat_compose_field"]
        XCTAssertTrue(composeField.waitForExistence(timeout: 2))
        composeField.tap()
        composeField.typeText("Quick benchmark ping.")

        let sendButton = app.buttons["chat_send_button"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 2))
        sendButton.tap()

        XCTAssertTrue(app.staticTexts["Quick benchmark ping."].waitForExistence(timeout: 2))
    }

    func testCreateCommunityFromCommunitiesTab() {
        app.buttons["tab_communities"].tap()
        app.buttons["community_new_button"].tap()

        let nameField = app.textFields["community_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Field Research\n")

        let createButton = app.buttons["community_create_button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2))
        createButton.tap()

        XCTAssertTrue(app.staticTexts["Field Research"].waitForExistence(timeout: 2))
    }
}
