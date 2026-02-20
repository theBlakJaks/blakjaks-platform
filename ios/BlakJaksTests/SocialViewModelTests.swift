import XCTest
@testable import BlakJaks

// MARK: - SocialViewModelTests

@MainActor
final class SocialViewModelTests: XCTestCase {

    private var socialVM: SocialViewModel!

    override func setUp() {
        super.setUp()
        socialVM = SocialViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        socialVM = nil
        super.tearDown()
    }

    // MARK: - loadChannels

    func testLoadChannelsPopulatesChannels() async {
        await socialVM.loadChannels()
        XCTAssertFalse(socialVM.channels.isEmpty)
        XCTAssertNil(socialVM.error)
    }

    func testLoadChannelsReturnsThreeChannels() async {
        await socialVM.loadChannels()
        XCTAssertEqual(socialVM.channels.count, 3)
    }

    func testLoadChannelsIsLoadingFalseAfterLoad() async {
        await socialVM.loadChannels()
        XCTAssertFalse(socialVM.isLoadingChannels)
    }

    func testLoadChannelsFirstChannelIsGeneral() async {
        await socialVM.loadChannels()
        XCTAssertEqual(socialVM.channels.first?.id, 1)
        XCTAssertEqual(socialVM.channels.first?.name, "General")
    }

    func testLoadChannelsThirdChannelIsVIPLounge() async {
        await socialVM.loadChannels()
        XCTAssertEqual(socialVM.channels.last?.id, 3)
        XCTAssertEqual(socialVM.channels.last?.name, "VIP Lounge")
    }

    // MARK: - selectChannel

    func testSelectChannelSetsSelectedChannel() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        XCTAssertEqual(socialVM.selectedChannel?.id, 1)
    }

    func testSelectChannelLoadsMessages() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        XCTAssertFalse(socialVM.messages.isEmpty)
    }

    func testSelectChannelResetsNewMessageCount() async {
        socialVM.newMessageCount = 5
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        XCTAssertEqual(socialVM.newMessageCount, 0)
    }

    func testSelectChannelSetsCorrectChannelName() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[1])
        XCTAssertEqual(socialVM.selectedChannel?.name, "Flavors")
    }

    func testSelectChannelIsLoadingMessagesFalseAfterSelect() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        XCTAssertFalse(socialVM.isLoadingMessages)
    }

    // MARK: - loadMessages

    func testLoadMessagesPopulatesMessages() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        XCTAssertEqual(socialVM.messages.count, 1)
    }

    func testLoadMessagesFirstMessageContent() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        XCTAssertEqual(socialVM.messages.first?.content, "Welcome to BlakJaks!")
    }

    // MARK: - sendMessage

    func testSendMessageAppendsToMessages() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        socialVM.draftMessage = "Hello world"
        let countBefore = socialVM.messages.count
        await socialVM.sendMessage()
        XCTAssertEqual(socialVM.messages.count, countBefore + 1)
        XCTAssertNil(socialVM.error)
    }

    func testSendMessageClearsDraft() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        socialVM.draftMessage = "Hello world"
        await socialVM.sendMessage()
        XCTAssertTrue(socialVM.draftMessage.isEmpty)
    }

    func testSendMessageRateLimitsStandardUser() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        socialVM.draftMessage = "msg1"
        await socialVM.sendMessage()
        // currentUserTier is "Standard", so rate limiting should engage after send
        XCTAssertTrue(socialVM.isRateLimited)
    }

    func testSendMessageEmptyDraftDoesNotSend() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        let countAfterSelect = socialVM.messages.count
        socialVM.draftMessage = ""
        await socialVM.sendMessage()
        // Empty draft should be rejected — message count must not increase
        XCTAssertEqual(socialVM.messages.count, countAfterSelect)
    }

    func testSendMessageWithoutChannelDoesNotSend() async {
        socialVM.draftMessage = "Hello"
        await socialVM.sendMessage()
        // No channel selected, guard fires — no messages appended
        XCTAssertTrue(socialVM.messages.isEmpty)
    }

    func testSendMessageWhitespaceOnlyDraftDoesNotSend() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        let countAfterSelect = socialVM.messages.count
        socialVM.draftMessage = "   \t  "
        await socialVM.sendMessage()
        XCTAssertEqual(socialVM.messages.count, countAfterSelect)
    }

    func testSendMessageSetsChannelIdCorrectly() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        socialVM.draftMessage = "Test message"
        await socialVM.sendMessage()
        XCTAssertEqual(socialVM.messages.last?.channelId, 1)
    }

    // MARK: - translateMessage

    func testTranslateMessageReturnsText() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        if let msg = socialVM.messages.first {
            let result = await socialVM.translateMessage(msg)
            XCTAssertEqual(result, "Translated text here")
        } else {
            XCTFail("Expected at least one message to translate")
        }
    }

    func testTranslateMessageReturnsNonNilString() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        if let msg = socialVM.messages.first {
            let result = await socialVM.translateMessage(msg)
            XCTAssertNotNil(result)
        } else {
            XCTFail("Expected at least one message to translate")
        }
    }

    // MARK: - addReaction

    func testAddReactionDoesNotThrow() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        if let msg = socialVM.messages.first {
            await socialVM.addReaction(to: msg, emoji: "💯")
            XCTAssertNil(socialVM.error)
        } else {
            XCTFail("Expected at least one message to react to")
        }
    }

    func testRemoveReactionDoesNotError() async {
        await socialVM.loadChannels()
        await socialVM.selectChannel(socialVM.channels[0])
        if let msg = socialVM.messages.first {
            await socialVM.removeReaction(from: msg, emoji: "🔥")
            XCTAssertNil(socialVM.error)
        } else {
            XCTFail("Expected at least one message to remove reaction from")
        }
    }

    // MARK: - clearError

    func testClearErrorSetsNil() async {
        // Confirm error starts nil; clearError() leaves it nil (no-op in clean state)
        XCTAssertNil(socialVM.error)
        socialVM.clearError()
        XCTAssertNil(socialVM.error)
    }

    // MARK: - initialState

    func testInitialChannelsEmpty() {
        XCTAssertTrue(socialVM.channels.isEmpty)
    }

    func testInitialMessagesEmpty() {
        XCTAssertTrue(socialVM.messages.isEmpty)
    }

    func testInitialSelectedChannelNil() {
        XCTAssertNil(socialVM.selectedChannel)
    }

    func testInitialDraftMessageEmpty() {
        XCTAssertTrue(socialVM.draftMessage.isEmpty)
    }

    func testInitialRateLimitedFalse() {
        XCTAssertFalse(socialVM.isRateLimited)
    }
}
