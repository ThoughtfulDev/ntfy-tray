import Foundation
import SwiftData

@Model
final class InboxMessage {
    var id: String
    var topic: String
    var topicIconIdentifier: String = TopicIconIdentifier.defaultValue
    var title: String
    var body: String
    var receivedAt: Date
    var priority: Int
    var tags: [String]
    var isRead: Bool
    var wasSilenced: Bool

    init(
        id: String,
        topic: String,
        topicIconIdentifier: String = TopicIconIdentifier.defaultValue,
        title: String,
        body: String,
        receivedAt: Date,
        priority: Int,
        tags: [String],
        isRead: Bool = false,
        wasSilenced: Bool = false
    ) {
        self.id = id
        self.topic = topic
        self.topicIconIdentifier = topicIconIdentifier
        self.title = title
        self.body = body
        self.receivedAt = receivedAt
        self.priority = priority
        self.tags = tags
        self.isRead = isRead
        self.wasSilenced = wasSilenced
    }
}
