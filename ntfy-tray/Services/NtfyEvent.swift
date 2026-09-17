import Foundation

nonisolated struct NtfyEvent: Codable, Sendable, Equatable {
    let id: String
    let time: TimeInterval
    let event: String
    let topic: String
    let message: String?
    let title: String?
    let tags: [String]?
    let priority: Int?

    var receivedAt: Date {
        Date(timeIntervalSince1970: time)
    }

    var isMessage: Bool {
        event == "message"
    }

    var isDelete: Bool {
        event == "message_delete"
    }

    var isClear: Bool {
        event == "message_clear"
    }
}
