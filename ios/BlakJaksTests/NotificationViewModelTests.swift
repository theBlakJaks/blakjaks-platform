import XCTest
@testable import BlakJaks

// MARK: - NotificationViewModelTests

@MainActor
final class NotificationViewModelTests: XCTestCase {

    private var notifVM: NotificationViewModel!

    override func setUp() {
        super.setUp()
        notifVM = NotificationViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        notifVM = nil
        super.tearDown()
    }

    // MARK: - initialState

    func testInitialNotificationsEmpty() {
        XCTAssertTrue(notifVM.notifications.isEmpty)
    }

    func testInitialUnreadCountZero() {
        XCTAssertEqual(notifVM.unreadCount, 0)
    }

    func testInitialIsLoadingFalse() {
        XCTAssertFalse(notifVM.isLoading)
    }

    func testInitialErrorNil() {
        XCTAssertNil(notifVM.error)
    }

    // MARK: - loadNotifications

    func testLoadNotificationsPopulatesNotifications() async {
        await notifVM.loadNotifications()
        XCTAssertFalse(notifVM.notifications.isEmpty)
        XCTAssertNil(notifVM.error)
    }

    func testLoadNotificationsReturnsTwoItems() async {
        await notifVM.loadNotifications()
        XCTAssertEqual(notifVM.notifications.count, 2)
    }

    func testLoadNotificationsSetsUnreadCount() async {
        await notifVM.loadNotifications()
        XCTAssertEqual(notifVM.unreadCount, 1)
    }

    func testLoadNotificationsIsLoadingFalseAfterLoad() async {
        await notifVM.loadNotifications()
        XCTAssertFalse(notifVM.isLoading)
    }

    func testLoadNotificationsFirstNotificationIsUnread() async {
        await notifVM.loadNotifications()
        XCTAssertEqual(notifVM.notifications.first?.id, 1)
        XCTAssertFalse(notifVM.notifications.first?.isRead ?? true)
    }

    func testLoadNotificationsSecondNotificationIsRead() async {
        await notifVM.loadNotifications()
        let second = notifVM.notifications.first(where: { $0.id == 2 })
        XCTAssertNotNil(second)
        XCTAssertTrue(second?.isRead ?? false)
    }

    func testLoadNotificationsFirstNotificationTitle() async {
        await notifVM.loadNotifications()
        XCTAssertEqual(notifVM.notifications.first?.title, "Comp Earned!")
    }

    func testLoadNotificationsSecondNotificationType() async {
        await notifVM.loadNotifications()
        let second = notifVM.notifications.first(where: { $0.id == 2 })
        XCTAssertEqual(second?.type, "tier_upgrade")
    }

    // MARK: - markRead

    func testMarkReadDoesNotError() async {
        await notifVM.loadNotifications()
        await notifVM.markRead(id: 1)
        XCTAssertNil(notifVM.error)
    }

    func testMarkReadTriggersReload() async {
        await notifVM.loadNotifications()
        let countBefore = notifVM.notifications.count
        await notifVM.markRead(id: 1)
        // markRead reloads from mock, which always returns the same 2 notifications
        XCTAssertEqual(notifVM.notifications.count, countBefore)
    }

    func testMarkReadIsLoadingFalseAfterCompletion() async {
        await notifVM.loadNotifications()
        await notifVM.markRead(id: 1)
        XCTAssertFalse(notifVM.isLoading)
    }

    // MARK: - markAllRead

    func testMarkAllReadDoesNotError() async {
        await notifVM.loadNotifications()
        await notifVM.markAllRead()
        XCTAssertNil(notifVM.error)
    }

    func testMarkAllReadSetsUnreadCountZero() async {
        await notifVM.loadNotifications()
        await notifVM.markAllRead()
        XCTAssertEqual(notifVM.unreadCount, 0)
    }

    func testMarkAllReadSetsAllNotificationsRead() async {
        await notifVM.loadNotifications()
        await notifVM.markAllRead()
        let anyUnread = notifVM.notifications.contains(where: { !$0.isRead })
        XCTAssertFalse(anyUnread)
    }

    func testMarkAllReadPreservesNotificationCount() async {
        await notifVM.loadNotifications()
        let countBefore = notifVM.notifications.count
        await notifVM.markAllRead()
        XCTAssertEqual(notifVM.notifications.count, countBefore)
    }

    // MARK: - clearError

    func testClearErrorSetsNil() async {
        // In the clean state error is already nil; verify clearError() is safe to call
        XCTAssertNil(notifVM.error)
        notifVM.clearError()
        XCTAssertNil(notifVM.error)
    }
}
