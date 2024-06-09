// Created by Daniel Amoafo on 6/6/2024.

import SwiftUI

enum Gradient {

    static func linear(
        colors: [Color] = [.Line.leading, .Line.trailing],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
        .init(
            gradient: .init(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    static func radial(
        colors: [Color] = [.Line.trailing, .Line.leading],
        center: UnitPoint = .center,
        startRadius: CGFloat = 50.0,
        endRadius: CGFloat = 100.0
    ) -> RadialGradient {
        .init(
            colors: colors,
            center: center,
            startRadius: startRadius,
            endRadius: endRadius
        )
    }

    static func angular(
        colors: [Color] = [.Line.leading, .Line.trailing],
        center: UnitPoint = .center
    ) -> AngularGradient {
        .init(
            colors: colors,
            center: center
        )
    }
}

#Preview {
    ContainerView()
}

private struct ContainerView: View {

    struct Item: Identifiable {
        let name: String
        let style: AnyShapeStyle

        var id: String { name }
    }

    let data: [Item] = [
        .init(name: "Linear", style: .init(Gradient.linear())),
        .init(name: "Radial", style: .init(Gradient.radial())),
        .init(name: "Angular", style: .init(Gradient.angular())),
    ]

    var body: some View {
        VStack {
            ForEach(data) { item in
                Rectangle()
                    .foregroundStyle(item.style)
                    .overlay {
                        VStack {
                            Spacer()
                            Text(item.name)
                                .typography(.title1Emphasized)
                        }
                    }
            }
        }
    }
}
