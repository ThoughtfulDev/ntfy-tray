//
//  AppModelInboxMaintenanceTests.swift
//  ntfy-trayTests
//

@testable import ntfy_tray
import Foundation
import SwiftData
import Testing

@MainActor
struct AppModelInboxMaintenanceTests {
    @Test func resetRestoresFirstRunStateAndRemovesLocalData() async throws {
        let tokenStore = ResetTestTokenStore(token: "secret")
        let notificationCoordinator = ResetTestNotificationCoordinator()
        let (appModel, modelContext) = try makeAppModel(
            tokenStore: tokenStore,
            notificationCoordinator: notificationCoordinator
        )
        await appModel.prepare(openInbox: {})

        let configuration = try #require(appModel.configuration)
        configuration.serverURLString = "https://notifications.example"
        configuration.didCompleteOnboarding = true
        configuration.isManualDoNotDisturbEnabled = true
        modelContext.insert(TopicSubscription(name: "alerts"))
        modelContext.insert(message(id: "message-1", topic: "alerts"))
        let quietHours = try modelContext.fetch(FetchDescriptor<QuietHoursRule>())
        quietHours.first?.isEnabled = true
        try modelContext.save()

        try await appModel.resetAppData()

        #expect(appModel.needsOnboarding)
        #expect(appModel.configuration?.serverURLString == "https://ntfy.sh")
        #expect(appModel.configuration?.isManualDoNotDisturbEnabled == false)
        #expect(try modelContext.fetchCount(FetchDescriptor<TopicSubscription>()) == 0)
        #expect(try modelContext.fetchCount(FetchDescriptor<InboxMessage>()) == 0)

        let resetQuietHours = try modelContext.fetch(FetchDescriptor<QuietHoursRule>())
        #expect(resetQuietHours.count == 7)
        #expect(resetQuietHours.allSatisfy { !$0.isEnabled })
        #expect(await tokenStore.wasDeleted())
        #expect(notificationCoordinator.removeAllCount == 1)
    }

    @Test func deletingOneMessageRemovesItsDeliveredNotification() async throws {
        let notificationCoordinator = ResetTestNotificationCoordinator()
        let (appModel, modelContext) = try makeAppModel(notificationCoordinator: notificationCoordinator)
        await appModel.prepare(openInbox: {})

        let deletedMessage = message(id: "delete-me", topic: "alerts")
        modelContext.insert(deletedMessage)
        modelContext.insert(message(id: "keep-me", topic: "builds"))
        try modelContext.save()

        appModel.deleteMessage(deletedMessage)

        #expect(try modelContext.fetchCount(FetchDescriptor<InboxMessage>()) == 1)
        #expect(notificationCoordinator.removedNotificationIdentifiers == ["delete-me"])
    }

    @Test func clearingTopicMessagesLeavesOtherTopicsUntouched() async throws {
        let notificationCoordinator = ResetTestNotificationCoordinator()
        let (appModel, modelContext) = try makeAppModel(notificationCoordinator: notificationCoordinator)
        await appModel.prepare(openInbox: {})

        modelContext.insert(message(id: "alert-1", topic: "alerts"))
        modelContext.insert(message(id: "alert-2", topic: "alerts"))
        modelContext.insert(message(id: "build-1", topic: "builds"))
        try modelContext.save()

        appModel.deleteMessages(forTopic: "alerts")

        let remainingMessages = try modelContext.fetch(FetchDescriptor<InboxMessage>())
        #expect(remainingMessages.map(\.id) == ["build-1"])
        #expect(Set(notificationCoordinator.removedNotificationIdentifiers) == Set(["alert-1", "alert-2"]))
    }

    private func makeAppModel(
        tokenStore: ResetTestTokenStore = ResetTestTokenStore(),
        notificationCoordinator: ResetTestNotificationCoordinator
    ) throws -> (AppModel, ModelContext) {
        let schema = Schema([
            ServerConfiguration.self,
            TopicSubscription.self,
            InboxMessage.self,
            QuietHoursRule.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        return (
            AppModel(
                modelContext: context,
                keychainStore: tokenStore,
                notificationCoordinator: notificationCoordinator
            ),
            context
        )
    }

    private func message(id: String, topic: String) -> InboxMessage {
        InboxMessage(
            id: id,
            topic: topic,
            title: "Test message",
            body: "A local inbox record.",
            receivedAt: .now,
            priority: 3,
            tags: []
        )
    }
}
