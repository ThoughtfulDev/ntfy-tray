enum TopicIconIdentifier {
    nonisolated static let fontAwesomePrefix = "fontawesome:"
    nonisolated static let defaultValue = "fontawesome:solid:bell"

    static func isFontAwesome(_ identifier: String) -> Bool {
        identifier.hasPrefix(fontAwesomePrefix)
    }
}
