// Created by Daniel Amoafo on 22/6/2023.

import SwiftUI

struct FloatingTitleRow: View {

    @Environment(\.sizeCategory) var sizeCategory

    let title: String?
    let text: Binding<String>
    let displayType: DisplayType
    let typography: Typography
    let titleColor: Color
    let textColor: Color
    let dividerConfig: HorizontalDivider.Config?

    init(
        title: String? = nil,
        text: Binding<String>,
        displayType: DisplayType = .textField,
        typography: Typography = .body,
        titleColor: Color = Color(.secondaryLabel),
        textColor: Color = Color(.label),
        dividerConfig: HorizontalDivider.Config? = nil
    ) {
        self.title = title ?? nil
        self.text = text
        self.displayType = displayType
        self.typography = typography
        self.titleColor = titleColor
        self.textColor = textColor
        self.dividerConfig = dividerConfig
    }

}

// MARK: - Rendering

extension FloatingTitleRow {

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                if titleIsAvailable {
                    Text(title ?? "")
                        .typography(typography)
                        .foregroundStyle(titleColor)
                        .offset(y: text.wrappedValue.isEmpty ? 0 : titleOffset * -1)
                        .scaleEffect(text.wrappedValue.isEmpty ? 1 : 0.8, anchor: .leading)
                }
                switch displayType {
                case .textField:
                    TextField("", text: text) // give TextField an empty placeholder
                        .font(typography.font)
                        .foregroundStyle(textColor)
                case .label:
                    Text(text.wrappedValue)
                        .typography(typography)
                        .foregroundStyle(textColor)
                }
            }
            .padding(.top, titleOffset * 0.7) // ensure title with offset is within views bounds
            .animation(.spring(.bouncy), value: text.wrappedValue)
            if let config = dividerConfig {
                HorizontalDivider(config: config)
            }
        }
    }

}

// MARK: - Logic

extension FloatingTitleRow {

    var titleIsAvailable: Bool {
        if let title, title.isNotEmpty {
            return true
        }
        return false
    }

    private var titleOffset: CGFloat {
        guard titleIsAvailable else {
            return 0
        }
        switch sizeCategory {
        case .extraSmall, .small, .medium, .large:
                return 25
        case .extraLarge, .extraExtraLarge:
                return 30
        case .extraExtraExtraLarge, .accessibilityMedium, .accessibilityLarge:
                return 35
        case .accessibilityExtraLarge, .accessibilityExtraExtraLarge:
                return 45
        case .accessibilityExtraExtraExtraLarge:
            return 50
        @unknown default:
           return 25
        }
    }

}

// MARK: - Data Types
extension FloatingTitleRow {

    enum DisplayType: Equatable {
        case textField
        case label
    }
}

// MARK: - Preview

private struct PreviewNoContentView: View {
    @State var text = ""

    var body: some View {
        FloatingTitleRow(title: "Field A - Animated", text: $text)
    }
}

private struct PreviewWithContentView: View {

    let text: String

    var body: some View {
        FloatingTitleRow(title: "Field", text: .constant("\(text)"))
    }
}

#Preview {
    ScrollView {
        VStack {
            Group {
                FloatingTitleRow(text: .constant("textfield with no title"), typography: .title1)

                PreviewNoContentView(text: "")

                FloatingTitleRow(title: "Field B", text: .constant("with a divider"), dividerConfig: .standard)

                FloatingTitleRow(title: "Field C", text: .constant("some editable text value"))

                FloatingTitleRow(title: "Field D", text: .constant("Lorem ipsum with color"), textColor: .blue)

                FloatingTitleRow(title: "Field E", text: .constant("disabled text"), textColor: Color(.placeholderText))
                    .disabled(true)
            }

            Group {
                Text("Size Categories")
                    .padding(.top)
                Divider()
                Group {
                    PreviewWithContentView(text: "extraSmall")
                        .environment(\.sizeCategory, .extraSmall)
                    PreviewWithContentView(text: "small")
                        .environment(\.sizeCategory, .small)
                    PreviewWithContentView(text: "medium")
                        .environment(\.sizeCategory, .medium)
                    PreviewWithContentView(text: "large")
                        .environment(\.sizeCategory, .large)
                }

                Group {
                    PreviewWithContentView(text: "extraLarge")
                        .environment(\.sizeCategory, .extraLarge)
                    PreviewWithContentView(text: "extraExtraLarge")
                        .environment(\.sizeCategory, .extraExtraLarge)
                PreviewWithContentView(text: "extraExtraExtraLarge")
                    .environment(\.sizeCategory, .extraExtraExtraLarge)
                }

                Group {
                    PreviewWithContentView(text: "accessibilityMedium")
                        .environment(\.sizeCategory, .accessibilityMedium)
                    PreviewWithContentView(text: "accessibilityLarge")
                        .environment(\.sizeCategory, .accessibilityLarge)
                    PreviewWithContentView(text: "accessibilityExtraLarge")
                        .environment(\.sizeCategory, .accessibilityExtraLarge)
                    PreviewWithContentView(text: "accessibilityExtraExtraLarge")
                        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
                    PreviewWithContentView(text: "accessibilityExtraExtraExtraLarge")
                        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                }
            }
        }
        .padding()
    }
}
