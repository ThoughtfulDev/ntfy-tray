@testable import ntfy_tray
import AppKit
import Foundation
import Testing
import UserNotifications

@MainActor
struct TopicNotificationIconAttachmentTests {
    @Test
    func createsAReadablePNGThumbnail() throws {
        let message = InboxMessage(
            id: "thumbnail-test",
            topic: "alerts",
            topicIconIdentifier: "bell.fill",
            title: "Test",
            body: "A test notification.",
            receivedAt: .now,
            priority: 3,
            tags: []
        )
        defer {
            TopicNotificationIconAttachment.removeAttachments(withIdentifiers: [message.id])
        }

        let generatedAttachment = try TopicNotificationIconAttachment.make(for: message)
        let attachment = try #require(generatedAttachment)

        #expect(attachment.url.pathExtension == "png")
        #expect(NSImage(contentsOf: attachment.url) != nil)
    }
}
