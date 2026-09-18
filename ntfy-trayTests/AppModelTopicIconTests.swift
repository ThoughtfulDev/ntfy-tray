@testable import ntfy_tray
import Foundation
import SwiftData
import Testing

@MainActor
struct AppModelTopicIconTests {
    @Test
    func savingTopicIconUpdatesItsLocalMessages() async throws {
        let schema = Schema([
            ServerConfiguration.self,
            TopicSubscription.self,
            InboxMessage.self,
            QuietHoursRule.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let model = AppModel(
            modelContext: context,
            keychainStore: ResetTestTokenStore(),
            notificationCoordinator: ResetTestNotificationCoordinator()
        )

        await model.prepare(openInbox: {})

        let topic = TopicSubscription(
            name: "alerts",
            symbolName: TopicIconIdentifier.defaultValue,
            isEnabled: false
        )
        let message = InboxMessage(
            id: "message-id",
            topic: "alerts",
            title: "Status",
            body: "All clear",
            receivedAt: .now,
            priority: 3,
            tags: []
        )
        context.insert(topic)
        context.insert(message)
        try context.save()

        topic.symbolName = "fontawesome:brands:github"
        model.saveTopicChanges()

        #expect(message.topicIconIdentifier == "fontawesome:brands:github")
    }
}
