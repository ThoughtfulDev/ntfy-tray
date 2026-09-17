//
//  ResetTestNotificationCoordinator.swift
//  ntfy-trayTests
//

@testable import ntfy_tray
@preconcurrency import UserNotifications

@MainActor
final class ResetTestNotificationCoordinator: NotificationCoordinating {
    private(set) var removedNotificationIdentifiers: [String] = []
    private(set) var removeAllCount = 0

    func configure(openInbox: @escaping () -> Void) {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        .notDetermined
    }

    func requestAuthorization() async throws -> Bool {
        true
    }

    func deliver(_ message: InboxMessage) async throws {}

    func removeNotifications(withIdentifiers identifiers: [String]) {
        removedNotificationIdentifiers.append(contentsOf: identifiers)
    }

    func removeAllNotifications() {
        removeAllCount += 1
    }
}
