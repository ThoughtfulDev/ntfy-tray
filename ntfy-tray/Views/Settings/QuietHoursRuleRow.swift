import SwiftUI

struct QuietHoursRuleRow: View {
    @Environment(AppModel.self) private var appModel
    @Bindable var rule: QuietHoursRule
    @State private var startDate: Date
    @State private var endDate: Date

    init(rule: QuietHoursRule) {
        self.rule = rule
        _startDate = State(initialValue: Self.date(for: rule.startMinutes))
        _endDate = State(initialValue: Self.date(for: rule.endMinutes))
    }

    var body: some View {
        HStack(spacing: 16) {
            Toggle(weekdayName, isOn: $rule.isEnabled)
                .frame(minWidth: 120, alignment: .leading)
            DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!rule.isEnabled)
            Text("to")
                .foregroundStyle(.secondary)
            DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!rule.isEnabled)
        }
        .onChange(of: rule.isEnabled) { _, _ in
            appModel.saveQuietHoursChanges()
        }
        .onChange(of: startDate) { _, newValue in
            rule.startMinutes = Self.minutes(for: newValue)
            appModel.saveQuietHoursChanges()
        }
        .onChange(of: endDate) { _, newValue in
            rule.endMinutes = Self.minutes(for: newValue)
            appModel.saveQuietHoursChanges()
        }
    }

    private var weekdayName: String {
        let symbols = Calendar.current.weekdaySymbols
        guard rule.weekday > 0, rule.weekday <= symbols.count else { return "Unknown" }
        return symbols[rule.weekday - 1]
    }

    private static func date(for minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    private static func minutes(for date: Date) -> Int {
        Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
    }
}
