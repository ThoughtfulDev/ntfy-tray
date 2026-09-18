import AppKit

@MainActor
enum MenuBarAppIcon {
    static let image: NSImage = {
        let symbol = NSImage(
            systemSymbolName: "bell.badge.fill",
            accessibilityDescription: "ntfy-tray"
        )!
        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = symbol.withSymbolConfiguration(configuration) ?? symbol
        image.isTemplate = true

        return image
    }()
}
