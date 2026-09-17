import SwiftUI

struct MessageDetail: View {
    let message: InboxMessage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(message.topic, systemImage: "number")
                    .foregroundStyle(.secondary)
                Text(message.title)
                    .font(.title2)
                    .bold()
                Text(message.body)
                    .textSelection(.enabled)
                Divider()
                LabeledContent("Received") {
                    Text(message.receivedAt, format: .dateTime.year().month().day().hour().minute())
                }
                LabeledContent("Priority") {
                    Text(message.priority, format: .number)
                }
                if !message.tags.isEmpty {
                    LabeledContent("Tags") {
                        Text(message.tags.joined(separator: ", "))
                            .textSelection(.enabled)
                    }
                }
                if message.wasSilenced {
                    Label("Delivered during Do Not Disturb", systemImage: "moon.zzz")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .navigationTitle("Notification")
    }
}
