// Created by Daniel Amoafo on 13/4/2024.

import SwiftUI

struct BackgroundShadowViewModifier: ViewModifier {

    let fillColor: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .fill(fillColor)
                .shadow(color: Color(R.color.shadow.shadow10), radius: 8, x: 0, y: 4)
                .shadow(color: Color(R.color.shadow.shadow11), radius: 4, x: 0, y: 2)
                .shadow(color: Color(R.color.shadow.shadow12), radius: 2, x: 0, y: 0)
            )
    }
}

extension View {

    func backgroundShadow(color: Color? = nil, cornerRadius: CGFloat? = nil) -> some View {
        modifier(
            BackgroundShadowViewModifier(
                fillColor: color ?? Color(R.color.surface.secondary),
                cornerRadius: cornerRadius ?? 14.0
            )
        )
    }
}

#Preview {

    VStack {
        Text("Hello World")
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
    }
    .backgroundShadow()
}
