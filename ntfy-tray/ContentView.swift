//
//  ContentView.swift
//  ntfy-tray
//
//  Created by Marc Hilgenberg on 17.09.26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Query(sort: \InboxMessage.receivedAt, order: .reverse) private var messages: [InboxMessage]
    @Query(sort: \TopicSubscription.createdAt) private var topics: [TopicSubscription]
    @State private var selection: InboxMessage?
    @State private var filter = InboxSelection.all
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var filteredMessages: [InboxMessage] {
        switch filter {
        case .all:
            messages
        case .unread:
            messages.filter { !$0.isRead }
        case let .topic(name):
            messages.filter { $0.topic.localizedCaseInsensitiveCompare(name) == .orderedSame }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $filter) {
                Section {
                    Label(InboxSelection.all.title, systemImage: InboxSelection.all.systemSymbolName)
                        .tag(InboxSelection.all)
                    Label(InboxSelection.unread.title, systemImage: InboxSelection.unread.systemSymbolName)
                        .tag(InboxSelection.unread)
                }

                if !topics.isEmpty {
                    Section("Topics") {
                        ForEach(topics) { topic in
                            Label {
                                Text(topic.name)
                            } icon: {
                                TopicIconView(identifier: topic.symbolName, size: 14)
                                    .accessibilityHidden(true)
                            }
                            .tag(InboxSelection.topic(topic.name))
                        }
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 240)
        } content: {
            List(filteredMessages, selection: $selection) { message in
                MessageRow(message: message)
                    .tag(message)
                    .contextMenu {
                        Button("Delete Message", systemImage: "trash", role: .destructive) {
                            delete(message)
                        }
                    }
            }
            .navigationTitle(filter.title)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
            .overlay {
                if filteredMessages.isEmpty {
                    ContentUnavailableView(
                        filter == .unread ? "No unread notifications" : "No notifications yet",
                        systemImage: filter == .unread ? "checkmark.circle" : "bell",
                        description: Text(filter == .unread ? "You are all caught up." : "Messages from your topics will appear here.")
                    )
                }
            }
        } detail: {
            Group {
                if let selection {
                    MessageDetail(message: selection)
                } else {
                    ContentUnavailableView("Select a notification", systemImage: "bell", description: Text("Choose a notification to see its details."))
                }
            }
            .navigationSplitViewColumnWidth(min: 360, ideal: 440)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup {
                Button("Mark All Read", systemImage: "checkmark.circle", action: appModel.markAllRead)
                    .disabled(appModel.unreadCount == 0)
                Button("Delete Message", systemImage: "trash", action: deleteSelectedMessage)
                    .disabled(selection == nil)
            }
        }
        .onChange(of: selection) { _, newSelection in
            if let newSelection {
                appModel.markRead(newSelection)
            }
        }
        .onChange(of: filter) {
            selection = nil
        }
        .onDeleteCommand(perform: deleteSelectedMessage)
    }

    private func deleteSelectedMessage() {
        guard let selection else { return }
        delete(selection)
    }

    private func delete(_ message: InboxMessage) {
        if selection === message {
            selection = nil
        }
        appModel.deleteMessage(message)
    }
}

#Preview {
    ContentView()
}
