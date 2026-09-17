import SwiftUI

struct TopicSettingsRow: View {
    @Environment(AppModel.self) private var appModel
    @Bindable var topic: TopicSubscription
    @State private var isClearMessagesConfirmationPresented = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: topic.symbolName)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(topic.name)
            Spacer()
            Picker("Icon for \(topic.name)", selection: $topic.symbolName) {
                ForEach(TopicSymbol.allCases) { symbol in
                    Label(symbol.title, systemImage: symbol.rawValue)
                        .tag(symbol.rawValue)
                }
            }
            .labelsHidden()
            Toggle("Enable \(topic.name)", isOn: $topic.isEnabled)
                .labelsHidden()
            Menu("Actions for \(topic.name)", systemImage: "ellipsis.circle") {
                Button("Clear Local Messages…", role: .destructive) {
                    isClearMessagesConfirmationPresented = true
                }
                .disabled(messageCount == 0)
            }
        }
        .onChange(of: topic.symbolName) { _, _ in
            appModel.saveTopicChanges()
        }
        .onChange(of: topic.isEnabled) { _, _ in
            appModel.saveTopicChanges()
        }
        .confirmationDialog(
            "Clear messages from \(topic.name)?",
            isPresented: $isClearMessagesConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Clear \(messageCount) Messages", role: .destructive) {
                appModel.deleteMessages(forTopic: topic.name)
            }
        } message: {
            Text("This removes \(messageCount) local messages for this topic. It does not delete the topic or change anything on the ntfy server.")
        }
    }

    private var messageCount: Int {
        appModel.messageCount(forTopic: topic.name)
    }
}
