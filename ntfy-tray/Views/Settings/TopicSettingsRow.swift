import SwiftUI

struct TopicSettingsRow: View {
    @Environment(AppModel.self) private var appModel
    @Bindable var topic: TopicSubscription

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
        }
        .onChange(of: topic.symbolName) { _, _ in
            appModel.saveTopicChanges()
        }
        .onChange(of: topic.isEnabled) { _, _ in
            appModel.saveTopicChanges()
        }
    }
}
