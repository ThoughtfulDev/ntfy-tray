import Foundation

struct FontAwesomeFreeIcon: Codable, Hashable, Identifiable {
    let identifier: String
    let name: String
    let label: String
    let style: String
    let unicode: String
    let searchTerms: [String]

    var id: String { identifier }

    var glyph: String {
        guard let codePoint = UInt32(unicode, radix: 16), let scalar = UnicodeScalar(codePoint) else {
            return "?"
        }
        return String(scalar)
    }

    var fontName: String {
        switch style {
        case "brands": "FontAwesome7Brands-Regular"
        case "regular": "FontAwesome7Free-Regular"
        default: "FontAwesome7Free-Solid"
        }
    }

    var styleTitle: String {
        switch style {
        case "brands": "Brand"
        case "regular": "Regular"
        default: "Solid"
        }
    }
}
