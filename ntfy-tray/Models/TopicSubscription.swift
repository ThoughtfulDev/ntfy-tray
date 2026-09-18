import Foundation
import SwiftData

@Model
final class TopicSubscription {
    var id: UUID
    var name: String
    var symbolName: String
    var isEnabled: Bool
    var createdAt: Date

    init(
        name: String,
        symbolName: String = TopicIconIdentifier.defaultValue,
        isEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}
