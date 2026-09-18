import Foundation

enum FontAwesomeFreeIconCatalog {
    static let icons: [FontAwesomeFreeIcon] = {
        guard
            let bundleURL = Bundle.main.url(forResource: "FontAwesomeFree", withExtension: "bundle"),
            let resourceBundle = Bundle(url: bundleURL),
            let iconsURL = resourceBundle.url(forResource: "icons", withExtension: "json"),
            let data = try? Data(contentsOf: iconsURL),
            let icons = try? JSONDecoder().decode([FontAwesomeFreeIcon].self, from: data)
        else {
            return []
        }
        return icons
    }()

    static let iconsByIdentifier = Dictionary(uniqueKeysWithValues: icons.map { ($0.identifier, $0) })

    static func icon(for identifier: String) -> FontAwesomeFreeIcon? {
        iconsByIdentifier[identifier]
    }
}
