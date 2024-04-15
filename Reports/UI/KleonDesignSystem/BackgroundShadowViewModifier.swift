// Created by Daniel Amoafo on 13/4/2024.

import SwiftUI

struct BackgroundShadowViewModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(Color(R.color.colors.surface.secondary))
                .shadow(color: Color(R.color.colors.shadow.shadow10), radius: 8, x: 0, y: 4)
                .shadow(color: Color(R.color.colors.shadow.shadow11), radius: 4, x: 0, y: 2)
                .shadow(color: Color(R.color.colors.shadow.shadow12), radius: 2, x: 0, y: 0)
            )
    }
}

extension View {

    func backgroundShadow() -> some View {
        modifier(BackgroundShadowViewModifier())
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
