import AppKit
import Foundation
@preconcurrency import UserNotifications

enum TopicNotificationIconAttachment {
    private static let directoryName = "ntfy-tray-notification-icons"

    static func make(for message: InboxMessage) throws -> UNNotificationAttachment? {
        guard let imageData = imageData(for: message.topicIconIdentifier) else {
            return nil
        }

        let directoryURL = attachmentDirectoryURL()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = attachmentFileURL(for: message.id)
        try imageData.write(to: fileURL, options: .atomic)

        return try UNNotificationAttachment(identifier: message.id, url: fileURL)
    }

    static func removeAttachments(withIdentifiers identifiers: [String]) {
        for identifier in identifiers {
            try? FileManager.default.removeItem(at: attachmentFileURL(for: identifier))
        }
    }

    static func removeAllAttachments() {
        try? FileManager.default.removeItem(at: attachmentDirectoryURL())
    }

    private static func attachmentDirectoryURL() -> URL {
        URL.temporaryDirectory.appending(path: directoryName, directoryHint: .isDirectory)
    }

    private static func attachmentFileURL(for messageIdentifier: String) -> URL {
        let safeIdentifier = Data(messageIdentifier.utf8)
            .base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")

        return attachmentDirectoryURL().appending(path: "\(safeIdentifier).png")
    }

    private static func imageData(for identifier: String) -> Data? {
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        if let icon = FontAwesomeFreeIconCatalog.icon(for: identifier) {
            draw(glyph: icon.glyph, fontName: icon.fontName, in: size)
        } else if let symbol = NSImage(systemSymbolName: identifier, accessibilityDescription: nil) {
            draw(symbol: symbol, in: size)
        } else {
            return nil
        }

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    private static func draw(glyph: String, fontName: String, in size: NSSize) {
        let font = NSFont(name: fontName, size: 176) ?? .systemFont(ofSize: 176)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        let text = glyph as NSString
        let bounds = text.boundingRect(
            with: NSSize(width: size.width, height: size.height),
            options: .usesLineFragmentOrigin,
            attributes: attributes
        )
        let origin = NSPoint(
            x: (size.width - bounds.width) / 2,
            y: (size.height - bounds.height) / 2 - bounds.origin.y
        )
        text.draw(at: origin, withAttributes: attributes)
    }

    private static func draw(symbol: NSImage, in size: NSSize) {
        let configuration = NSImage.SymbolConfiguration(pointSize: 176, weight: .regular)
        let configuredSymbol = symbol.withSymbolConfiguration(configuration) ?? symbol
        let drawSize = configuredSymbol.size
        let drawRect = NSRect(
            x: (size.width - drawSize.width) / 2,
            y: (size.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        configuredSymbol.draw(in: drawRect)
    }
}
