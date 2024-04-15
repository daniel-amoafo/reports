// Created by Daniel Amoafo on 24/6/2023.

import SwiftUI

public enum Typography: String, CaseIterable {

    case body
    case bodyEmphasized
    case bodyItalic
    case bodyItalicEmphasized
    case headlineEmphasized
    case largeTitle
    case largeTitleEmphasized
    case title1
    case title1Emphasized
    case title2
    case title2Emphasized
    case title3Emphasized

}

// MARK: - Public extensions

public extension Typography {

    var fontFamily: FontFamily {
        switch self {
        case .body: return .openSansRegular
        case .bodyEmphasized: return .openSansSemiBold
        case .bodyItalic: return .openSansItalic
        case .bodyItalicEmphasized: return .openSansSemiBoldItalic
        case .headlineEmphasized: return .cairoSemiBold
        case .largeTitle: return .cairoRegular
        case .largeTitleEmphasized: return .openSansSemiBold
        case .title1: return .cairoRegular
        case .title1Emphasized: return .cairoBold
        case .title2: return .cairoRegular
        case .title2Emphasized: return .cairoBold
        case .title3Emphasized: return .cairoBold
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .body, .bodyItalic, .bodyEmphasized, .bodyItalicEmphasized: return .body
        case .headlineEmphasized: return .headline
        case .largeTitle, .largeTitleEmphasized: return .largeTitle
        case .title1, .title1Emphasized: return .title
        case .title2, .title2Emphasized: return .title2
        case .title3Emphasized: return .title3
        }
    }

    var font: Font {
        return font(size: defaultSize, relativeTo: textStyle)
    }

    var isAccessibleHeading: Bool {
        switch self {
        case .largeTitle, .largeTitleEmphasized, .title1, .title1Emphasized:
            return true
        default:
            return false
        }
    }

    var defaultSize: CGFloat {
        switch self {
        case .body, .bodyItalic, .bodyEmphasized, .bodyItalicEmphasized: return 12
        case .headlineEmphasized: return 16
        case .largeTitle, .largeTitleEmphasized: return 34
        case .title1, .title1Emphasized: return 28
        case .title2, .title2Emphasized: return 22
        case .title3Emphasized: return 18
        }
    }
}

// MARK: - Data Types

public extension Typography {

    enum FontFamily: String, CaseIterable {
        case cairoBlack = "Cairo-Black"
        case cairoBold = "Cairo-Bold"
        case cairoExtraBold = "Cairo-ExtraBold"
        case cairoExtraLight = "Cairo-ExtraLight"
        case cairoLight = "Cairo-Light"
        case cairoMedium = "Cairo-Medium"
        case cairoRegular = "Cairo-Regular"
        case cairoSemiBold = "Cairo-SemiBold"
        case openSansRegular = "OpenSans-Regular"
        case openSansItalic = "OpenSans-Italic"
        case openSansSemiBold = "OpenSans-SemiBold"
        case openSansSemiBoldItalic = "OpenSans-SemiBoldItalic"
    }

}

// MARK: -

private extension Typography {

    static var fontFullNameMapping: [String: String] = [:]

    func font(size: CGFloat, relativeTo: Font.TextStyle = .body) -> Font {
        _ = Self.registerWeightsOnce

        guard let name = Self.fontFullNameMapping[fontFamily.rawValue] else {
           fatalError("could not find font name mapping for font '\(self)'.")
        }

        return .custom(name, size: size, relativeTo: relativeTo)
    }

    static func loadFonts() {
        for font in FontFamily.allCases {
            loadFont(name: font.rawValue)
        }
    }

    static func loadFont(name: String) {
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
    static let registerWeightsOnce: () = {
        // We call `familyNames` before registering fonts to avoid a possible deadlock bug.
        // http://stackoverflow.com/questions/24900979/cgfontcreatewithdataprovider-hangs-in-airplane-mode
        _ = UIFont.familyNames

        loadFonts()
    }()
}

// MARK: - Text extensions

public extension Text {

    func typography(_ typography: Typography) -> some View {
        self
            .font(typography.font)
            .accessibilityAddTraits(typography.isAccessibleHeading ? [.isHeader] : [])
    }

}

// MARK: - Previews

struct Typography_Previews: PreviewProvider {

    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Typography.allCases, id: \.rawValue) { type in
                    Text(type.rawValue)
                        .typography(type)
                }
            }
        }
    }
}
