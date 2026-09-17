@preconcurrency import UserNotifications

@MainActor
protocol NotificationCoordinating: AnyObject {
    func configure(openInbox: @escaping () -> Void)
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func deliver(_ message: InboxMessage) async throws
    func removeNotifications(withIdentifiers identifiers: [String])
    func removeAllNotifications()
}
