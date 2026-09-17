import Foundation
import SwiftData

@Model
final class QuietHoursRule {
    /// Calendar weekday values use 1 for Sunday through 7 for Saturday.
    var weekday: Int
    var isEnabled: Bool
    var startMinutes: Int
    var endMinutes: Int

    init(
        weekday: Int,
        isEnabled: Bool = false,
        startMinutes: Int = 1_320,
        endMinutes: Int = 420
    ) {
        self.weekday = weekday
        self.isEnabled = isEnabled
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
    }
}
