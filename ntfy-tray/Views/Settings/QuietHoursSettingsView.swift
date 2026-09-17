import SwiftData
import SwiftUI

struct QuietHoursSettingsView: View {
    @Query(sort: \QuietHoursRule.weekday) private var rules: [QuietHoursRule]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiet Hours")
                .font(.title2)
                .bold()
            Text("Messages are saved in Inbox but do not alert you during these periods.")
                .foregroundStyle(.secondary)
            List(rules) { rule in
                QuietHoursRuleRow(rule: rule)
            }
        }
    }
}
