import Foundation

enum InboxFilter: String, CaseIterable, Identifiable {
    case all
    case unread

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All Notifications"
        case .unread: "Unread"
        }
    }

    var symbolName: String {
        switch self {
        case .all: "tray.full"
        case .unread: "circle.fill"
        }
    }
}
