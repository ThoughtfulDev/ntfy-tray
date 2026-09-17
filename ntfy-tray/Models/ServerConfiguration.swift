import Foundation
import SwiftData

@Model
final class ServerConfiguration {
    var id: UUID
    var serverURLString: String
    var didCompleteOnboarding: Bool
    var isManualDoNotDisturbEnabled: Bool

    init(
        serverURLString: String = "https://ntfy.sh",
        didCompleteOnboarding: Bool = false,
        isManualDoNotDisturbEnabled: Bool = false
    ) {
        id = UUID()
        self.serverURLString = serverURLString
        self.didCompleteOnboarding = didCompleteOnboarding
        self.isManualDoNotDisturbEnabled = isManualDoNotDisturbEnabled
    }

    var serverURL: URL? {
        URL(string: serverURLString)
    }
}
