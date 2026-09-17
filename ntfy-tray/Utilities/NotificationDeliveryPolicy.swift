import Foundation

nonisolated enum NotificationDeliveryPolicy {
    static func shouldDeliver(isAuthorized: Bool, isQuiet: Bool) -> Bool {
        isAuthorized && !isQuiet
    }
}
