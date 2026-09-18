import CoreText
import Foundation

enum FontAwesomeFontRegistrar {
    static func registerFonts() {
        guard let bundleURL = Bundle.main.url(forResource: "FontAwesomeFree", withExtension: "bundle") else {
            return
        }

        let fontNames = [
            "Font Awesome 7 Brands-Regular-400.otf",
            "Font Awesome 7 Free-Regular-400.otf",
            "Font Awesome 7 Free-Solid-900.otf"
        ]

        for fontName in fontNames {
            let fontURL = bundleURL.appending(path: "Fonts/\(fontName)")
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
