import Foundation

enum ConnectionState: Equatable, Sendable {
    case idle
    case connecting
    case connected
    case reconnecting
    case failed(String)

    var symbolName: String {
        switch self {
        case .idle, .connecting, .reconnecting:
            "arrow.triangle.2.circlepath"
        case .connected:
            "bolt.horizontal.circle.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }

    var label: String {
        switch self {
        case .idle:
            "Not connected"
        case .connecting:
            "Connecting"
        case .connected:
            "Connected"
        case .reconnecting:
            "Reconnecting"
        case let .failed(message):
            message
        }
    }
}
