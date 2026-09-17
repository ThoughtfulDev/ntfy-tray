import Foundation

struct QuietHoursEvaluator {
    static func isQuiet(at date: Date, rules: [QuietHoursRule], calendar: Calendar = .current) -> Bool {
        let currentWeekday = calendar.component(.weekday, from: date)
        let currentMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let previousWeekday = currentWeekday == 1 ? 7 : currentWeekday - 1

        return rules.contains { rule in
            guard rule.isEnabled else { return false }

            if rule.weekday == currentWeekday, contains(currentMinutes, rule: rule) {
                return true
            }

            return rule.weekday == previousWeekday
                && rule.startMinutes > rule.endMinutes
                && currentMinutes < rule.endMinutes
        }
    }

    private static func contains(_ minutes: Int, rule: QuietHoursRule) -> Bool {
        if rule.startMinutes == rule.endMinutes {
            return true
        }

        if rule.startMinutes < rule.endMinutes {
            return minutes >= rule.startMinutes && minutes < rule.endMinutes
        }

        return minutes >= rule.startMinutes
    }
}
