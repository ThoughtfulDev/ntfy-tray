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
    @State private var selection: InboxMessage?
    @State private var filter = InboxFilter.all

    private var filteredMessages: [InboxMessage] {
        switch filter {
        case .all:
            messages
        case .unread:
            messages.filter { !$0.isRead }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(InboxFilter.allCases, selection: $filter) { filter in
                Label(filter.title, systemImage: filter.symbolName)
                    .tag(filter)
            }
            .navigationTitle("Inbox")
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
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
            if let selection {
                MessageDetail(message: selection)
            } else {
                ContentUnavailableView("Select a notification", systemImage: "bell", description: Text("Choose a notification to see its details."))
            }
        }
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
