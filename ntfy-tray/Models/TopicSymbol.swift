import Foundation

enum TopicSymbol: String, CaseIterable, Identifiable {
    case bell = "bell.fill"
    case checkmark = "checkmark.circle.fill"
    case warning = "exclamationmark.triangle.fill"
    case terminal = "terminal.fill"
    case house = "house.fill"
    case heart = "heart.fill"
    case lock = "lock.fill"
    case server = "server.rack"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bell: "Bell"
        case .checkmark: "Checkmark"
        case .warning: "Warning"
        case .terminal: "Terminal"
        case .house: "Home"
        case .heart: "Heart"
        case .lock: "Lock"
        case .server: "Server"
        }
    }
}
