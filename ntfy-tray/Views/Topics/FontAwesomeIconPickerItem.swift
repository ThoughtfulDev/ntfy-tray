import SwiftUI

struct FontAwesomeIconPickerItem: View {
    let icon: FontAwesomeFreeIcon
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 8) {
                TopicIconView(identifier: icon.identifier, size: 24)
                    .accessibilityHidden(true)
                Text(icon.label)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(icon.styleTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(icon.label), \(icon.styleTitle)")
        .accessibilityValue(isSelected ? "Selected" : "")
    }
}
