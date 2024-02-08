// Created by Daniel Amoafo on 24/6/2023.

import SwiftUI

public enum FontWeight: CaseIterable {

    case light
    case lightItalic
    case regular
    case regularItalic
    case medium
    case mediumItalic
    case semiBold
    case semiBoldItalic
    case bold
    case boldItalic
    case extraBold
    case extraBoldItalic
    case black
    case blackItalic

    func font(size: CGFloat) -> Font {
        _ = FontWeight.registerWeightsOnce

        guard let name = Self.fontFullNameMapping[fontFamily.rawValue] else {
           fatalError("could not find font name mapping for font '\(self)'.")
        }

        return Font.custom(name, size: size)
    }

    func uifont(textStyle: UIFont.TextStyle) -> UIFont {
        _ = FontWeight.registerWeightsOnce

        guard let name = Self.fontFullNameMapping[fontFamily.rawValue] else {
           fatalError("could not find font name mapping for font '\(self)'.")
        }

        let scaledSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        let variation = kCTFontVariationAttribute as UIFontDescriptor.AttributeName
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: name, variation: axisVariations,
        ])

        let uifont = UIFont(descriptor: descriptor, size: scaledSize)

        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: uifont)
    }
}

extension FontWeight {

    enum FontFamily: String, CaseIterable {
        case redHatDisplay = "RedHatDisplay-VariableFont_wght"
        case redHatDisplayItalic = "RedHatDisplay-Italic-VariableFont_wght"
    }

    var fontFamily: FontFamily {
        switch self {
        case .light, .regular, .medium, .semiBold, .bold, .extraBold, .black:
            return .redHatDisplay
        case .lightItalic, .regularItalic, .mediumItalic, .semiBoldItalic, .boldItalic, .extraBoldItalic, .blackItalic:
            return .redHatDisplayItalic
        }
    }

    var axisVariations: [Int: Any] {
        let variations: [Axis.Variation: Any]
        switch self {
        case .light, .lightItalic:
            variations = [.weight: 300]
        case .regular, .regularItalic:
            variations = [.weight: 400]
        case .medium, .mediumItalic:
            variations = [.weight: 500]
        case .semiBold, .semiBoldItalic:
            variations = [.weight: 600]
        case .bold, .boldItalic:
            variations = [.weight: 700]
        case .extraBold, .extraBoldItalic:
            variations = [.weight: 800]
        case .black, .blackItalic:
            variations = [.weight: 900]
        }

        return variations.reduce(into: [:]) { (result: inout [Int: Any], item) in
            result[item.key.rawValue] = item.value
        }
    }
}

// MARK: - Automatic Loading

private extension FontWeight {

    static var fontFullNameMapping: [String: String] = [:]

    static func loadFonts() {
        for font in FontFamily.allCases {
            loadFont(name: font.rawValue)
        }
    }

    private static func loadFont(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf"),
              let data = try? Data(contentsOf: url),
              let dataRef = CGDataProvider(data: data as CFData),
              let font = CGFont(dataRef)
        else {
            return
        }

        CTFontManagerRegisterGraphicsFont(font, nil)

        if let fullName = font.fullName as? String {
            fontFullNameMapping[name] = fullName
        }
    }

    // This will be executed once when the first call is made to get a font
    private static let registerWeightsOnce: () = {
        // We call `familyNames` before registering fonts to avoid a possible deadlock bug.
        // http://stackoverflow.com/questions/24900979/cgfontcreatewithdataprovider-hangs-in-airplane-mode
        _ = UIFont.familyNames

        loadFonts()
    }()
}
