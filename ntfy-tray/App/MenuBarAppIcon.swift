import AppKit

@MainActor
enum MenuBarAppIcon {
    static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        NSApp.applicationIconImage.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: NSApp.applicationIconImage.size),
            operation: .sourceOver,
            fraction: 1
        )
        image.unlockFocus()
        image.isTemplate = false

        return image
    }()
}
