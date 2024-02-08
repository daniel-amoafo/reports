// Created by Daniel Amoafo on 24/6/2023.

import SwiftUI

public enum Typography: String, CaseIterable {

    case body
    case callout
    case caption
    case caption2
    case footnote
    case headline
    case largeTitle
    case subheadline
    case title
    case title2
    case title3

}

// MARK: - Public extensions

public extension Typography {

    var fontWeight: FontWeight {
        switch self {
        case .body: return .regular
        case .callout: return .light
        case .caption: return .bold
        case .caption2: return .boldItalic
        case .footnote: return .lightItalic
        case .headline: return .bold
        case .largeTitle: return .black
        case .subheadline: return .bold
        case .title: return .medium
        case .title2: return .medium
        case .title3: return .medium
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .body: return .body
        case .callout: return .callout
        case .caption: return .caption
        case .caption2: return .caption2
        case .footnote: return .footnote
        case .headline: return .headline
        case .largeTitle: return .largeTitle
        case .subheadline: return .subheadline
        case .title: return .title
        case .title2: return .title2
        case .title3: return .title3
        }
    }

    var font: Font {
        return fontWeight.font(size: 12)
    }

    var uiFont: UIFont {
        fontWeight.uifont(textStyle: textStyle.uiTextStyle)
    }

    var isAccessibleHeading: Bool {
        switch self {
        case .largeTitle, .headline, .title, .title2, .title3:
            return true
        default:
            return false
        }
    }
}

// MARK: - Text extensions

public extension Text {

    func typography(_ typography: Typography) -> some View {
        self
            .font(typography.font)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(typography.isAccessibleHeading ? [.isHeader] : [])
    }

}

extension Font.TextStyle {

    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .body: return .body
        case .callout: return .callout
        case .caption: return .caption1
        case .caption2: return .caption2
        case .footnote: return .footnote
        case .headline: return .headline
        case .largeTitle: return .largeTitle
        case .subheadline: return .subheadline
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        @unknown default:
            fatalError("font style not known for mapping (\(self)")
        }
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
