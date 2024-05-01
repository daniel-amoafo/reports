// Created by Daniel Amoafo on 8/2/2024.

import SwiftUI

struct HorizontalDivider: View {

    let color: Color
    let height: CGFloat

    init() {
        self.init(config: .standard)
    }

    init(config: Self.Config) {
        self.init(color: config.color, height: config.height)
    }

    init(color: Color, height: CGFloat) {
        self.color = color
        self.height = height
    }

    var body: some View {
        color
            .frame(height: height)
    }
}

extension HorizontalDivider {

    struct Config {
        let color: Color
        let height: CGFloat
    }
}

extension HorizontalDivider.Config {

    static let standard: Self = .init(
        color: Color.Border.secondary, height: 0.5
    )
}

#Preview {
    HorizontalDivider()
}
