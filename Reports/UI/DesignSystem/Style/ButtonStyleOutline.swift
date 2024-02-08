// Created by Daniel Amoafo on 25/6/2023.

import SwiftUI

struct OutlineButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(color(for: configuration))
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(color(for: configuration))
            )
            .contentShape(Rectangle())
    }

    private func color(for config: Configuration) -> Color {
        let color: Color
        if let role = config.role, role == .destructive {
            color = .red
        } else {
            color = Color.accentColor
        }
        return config.isPressed ? color.opacity(0.5) : color
    }
}

extension ButtonStyle where Self == OutlineButtonStyle {

    static var outlined: Self {
        OutlineButtonStyle()
    }

}

#Preview {
    Button("Destructive", role: .destructive, action: {})
        .buttonStyle(OutlineButtonStyle())
        .padding()
}
