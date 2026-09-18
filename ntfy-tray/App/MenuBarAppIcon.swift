import AppKit

@MainActor
enum MenuBarAppIcon {
    private static let bell = makeImage(
        named: "bell.badge.fill",
        accessibilityDescription: "ntfy-tray"
    )
    private static let mutedBell = makeImage(
        named: "bell.slash.fill",
        accessibilityDescription: "ntfy-tray Do Not Disturb"
    )

    static func image(isMuted: Bool) -> NSImage {
        isMuted ? mutedBell : bell
    }

    private static func makeImage(named name: String, accessibilityDescription: String) -> NSImage {
        let symbol = NSImage(
            systemSymbolName: name,
            accessibilityDescription: accessibilityDescription
        )!
        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = symbol.withSymbolConfiguration(configuration) ?? symbol
        image.isTemplate = true

        return image
    }
}
