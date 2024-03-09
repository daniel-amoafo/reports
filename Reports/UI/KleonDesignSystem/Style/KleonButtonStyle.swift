// Created by Daniel Amoafo on 9/3/2024.

import SwiftUI

struct KleonButtonStyle: ButtonStyle {

    enum Theme {
        case primary, secondary, outline
    }

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    let theme: Theme
    var typography: Typography = .title3Emphasized

    func makeBody(configuration: Configuration) -> some View {
        let isDarkColorScheme = colorScheme == .dark
        return configuration
            .label
            .frame(maxWidth: .infinity)
            .font(typography.font)
            .foregroundColor(theme.color(isPressed: configuration.isPressed))
            .padding(.horizontal, .Spacing.small)
            .padding(.vertical, .Spacing.xsmall)
            .background(
                backgroundShape
                    .fill(
                        theme.backgroundColor(
                            isPressed: configuration.isPressed,
                            isDarkColorScheme: isDarkColorScheme
                        )
                    )
                    .stroke(
                        theme.borderColor(
                            isPressed: configuration.isPressed,
                            isDarkColorScheme: isDarkColorScheme
                        ),
                        lineWidth: configuration.isPressed ? 1 : 2
                    )
            )
            .compositingGroup()
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .contentShape(backgroundShape)
            .animation(
                AnimationConstants.buttonHighlightAnimation(configuration.isPressed),
                value: configuration.isPressed
            )
    }

    private var backgroundShape: some Shape {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
    }
}

extension KleonButtonStyle.Theme {

    func color(isPressed: Bool) -> Color {
        let baseColor: Color
        switch self {
        case .primary:
            baseColor = Color(R.color.colors.button.primaryTitle)
        case .secondary:
            baseColor = Color(R.color.colors.button.secondaryTitle)
        case .outline:
            baseColor = isPressed ? .black : Color(R.color.colors.button.outline)
        }
        guard isPressed else {
            return baseColor
        }
        return baseColor.opacity(0.5)
    }

    func backgroundColor(isPressed: Bool, isDarkColorScheme: Bool) -> Color {
        let baseColor: Color
        switch self {
        case .primary:
            baseColor = Color(R.color.colors.button.primary)
        case .secondary:
            baseColor = Color(R.color.colors.button.secondary)
        case .outline:
            if isPressed {
                baseColor = .gray.lighter(by: isDarkColorScheme ? 0 : 50)
            } else {
                baseColor = .clear
            }
        }
        guard isPressed else {
            return baseColor
        }
        return isDarkColorScheme ? baseColor.lighter(by: 10) : baseColor.darker(by: 10)
    }

    func borderColor(isPressed: Bool, isDarkColorScheme: Bool) -> Color {
        let baseColor: Color
        switch self {
        case .primary, .secondary:
            baseColor = .clear
        case .outline:
            baseColor = isPressed ? .gray : Color(R.color.colors.button.outline)
        }
        guard isPressed else {
            return baseColor
        }
        return isDarkColorScheme ? baseColor.lighter(by: 10) : baseColor.darker(by: 10)
    }
}

extension ButtonStyle where Self == KleonButtonStyle {

    static var kleonPrimary: Self {
        KleonButtonStyle(theme: .primary)
    }

    static var kleonSecondary: Self {
        KleonButtonStyle(theme: .secondary)
    }

    static var kleonOutline: Self {
        KleonButtonStyle(theme: .outline)
    }

}

#Preview {
    VStack(spacing: 8) {
        Button("Primary", action: {})
            .buttonStyle(.kleonPrimary)

        Button("Secondary", action: {})
            .buttonStyle(.kleonSecondary)

        Button("Outline", action: {})
            .buttonStyle(.kleonOutline)
    }
    .padding(.horizontal)
}
