import SwiftData
import SwiftUI

struct TopicsSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Query(sort: \TopicSubscription.createdAt) private var topics: [TopicSubscription]
    @State private var isAddingTopic = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Topics")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Add Topic", systemImage: "plus") {
                    isAddingTopic = true
                }
            }

            if topics.isEmpty {
                ContentUnavailableView("No topics", systemImage: "bell", description: Text("Add a topic to start receiving notifications."))
            } else {
                List {
                    ForEach(topics) { topic in
                        TopicSettingsRow(topic: topic)
                    }
                    .onDelete(perform: deleteTopics)
                }
            }
        }
        .sheet(isPresented: $isAddingTopic) {
            AddTopicView()
        }
    }

    private func deleteTopics(at offsets: IndexSet) {
        offsets.map { topics[$0] }.forEach(appModel.deleteTopic)
    }
}
