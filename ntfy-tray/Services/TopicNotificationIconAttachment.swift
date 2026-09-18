import AppKit
import Foundation
import UniformTypeIdentifiers
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

        let options: [AnyHashable: Any] = [
            UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier,
            UNNotificationAttachmentOptionsThumbnailHiddenKey: false,
        ]
        return try UNNotificationAttachment(identifier: message.id, url: fileURL, options: options)
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
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return nil
        }
        bitmap.size = size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.restoreGraphicsState() }

        let background = NSBezierPath(
            roundedRect: NSRect(origin: .zero, size: size),
            xRadius: 64,
            yRadius: 64
        )
        NSColor.systemIndigo.setFill()
        background.fill()

        if let icon = FontAwesomeFreeIconCatalog.icon(for: identifier) {
            draw(glyph: icon.glyph, fontName: icon.fontName, in: size)
        } else if let symbol = NSImage(systemSymbolName: identifier, accessibilityDescription: nil) {
            draw(symbol: symbol, in: size)
        } else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }

    private static func draw(glyph: String, fontName: String, in size: NSSize) {
        let font = NSFont(name: fontName, size: 156) ?? .systemFont(ofSize: 156, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
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
        let configuration = NSImage.SymbolConfiguration(pointSize: 156, weight: .medium)
        let configuredSymbol = symbol.withSymbolConfiguration(configuration) ?? symbol
        let drawSize = configuredSymbol.size
        let drawRect = NSRect(
            x: (size.width - drawSize.width) / 2,
            y: (size.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        NSColor.white.set()
        configuredSymbol.draw(in: drawRect)
    }
}
