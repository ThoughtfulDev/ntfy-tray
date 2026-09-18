@preconcurrency import UserNotifications
import Foundation

@MainActor
final class NotificationCoordinator: NSObject, NotificationCoordinating, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var openInbox: (() -> Void)?

    func configure(openInbox: @escaping () -> Void) {
        self.openInbox = openInbox
        center.delegate = self
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func deliver(_ message: InboxMessage) async throws {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.subtitle = message.topic
        content.threadIdentifier = message.topic
        content.userInfo = ["messageID": message.id]
        if let attachment = try? TopicNotificationIconAttachment.make(for: message) {
            content.attachments = [attachment]
        }

        let request = UNNotificationRequest(identifier: message.id, content: content, trigger: nil)
        try await center.add(request)
    }

    func removeNotifications(withIdentifiers identifiers: [String]) {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        TopicNotificationIconAttachment.removeAttachments(withIdentifiers: identifiers)
    }

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        TopicNotificationIconAttachment.removeAllAttachments()
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive _: UNNotificationResponse
    ) async {
        await MainActor.run { [weak self] in
            self?.openInbox?()
        }
    }
}
