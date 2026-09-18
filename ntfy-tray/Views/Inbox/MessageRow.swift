import SwiftUI

struct MessageRow: View {
    let message: InboxMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TopicIconView(identifier: message.topicIconIdentifier, size: 16)
                .foregroundStyle(message.isRead ? Color.secondary : Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .lineLimit(1)
                    .bold(message.isRead == false)
                Text(message.body)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                Text(message.receivedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.isRead ? "Read" : "Unread") notification: \(message.title)")
    }
}
