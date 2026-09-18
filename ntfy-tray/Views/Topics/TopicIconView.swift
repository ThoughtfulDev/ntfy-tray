import SwiftUI

struct TopicIconView: View {
    let identifier: String
    var size: CGFloat = 16

    var body: some View {
        if let icon = FontAwesomeFreeIconCatalog.icon(for: identifier) {
            Text(icon.glyph)
                .font(.custom(icon.fontName, size: size))
                .frame(width: size, height: size)
                .accessibilityLabel(icon.label)
        } else {
            Image(systemName: identifier)
                .font(.system(size: size))
                .frame(width: size, height: size)
                .accessibilityLabel(identifier)
        }
    }
}
