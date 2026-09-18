enum InboxSelection: Hashable {
    case all
    case unread
    case topic(String)

    var title: String {
        switch self {
        case .all: "All Notifications"
        case .unread: "Unread"
        case let .topic(name): name
        }
    }

    var systemSymbolName: String {
        switch self {
        case .all: "tray.full"
        case .unread: "circle.fill"
        case .topic: "bell"
        }
    }
}
