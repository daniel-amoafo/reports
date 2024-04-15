// Created by Daniel Amoafo on 14/4/2024.

import SwiftUI

struct BottomShadowViewModifier: ViewModifier {

    let opacity: CGFloat

    func body(content: Content) -> some View {
        content
            .background(shadow)
    }

    private var shadow: some View {
        Rectangle()
            .fill(Color(R.color.colors.surface.primary))
            .shadow(color: Color(R.color.colors.shadow.shadowBottom), radius: 4, x: 0, y: 4)
            .opacity(opacity)
    }
}

extension View {

    func bottomShadow(opacity: CGFloat = 1.0) -> some View {
        modifier(BottomShadowViewModifier(opacity: opacity))
    }
}

#Preview {
    VStack {
        Text("Hello")
    }
    .frame(maxWidth: .infinity)
    .bottomShadow()
//
}
