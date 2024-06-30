// Created by Daniel Amoafo on 6/6/2024.

import SwiftUI

enum KleonGradient {

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

    static func onboarding() -> EllipticalGradient {
        let colorStops: [Gradient.Stop] = [
            .init(color: Color.Onboarding.stop1, location: 0.1),
            .init(color: Color.Onboarding.stop2, location: 0.4),
            .init(color: Color.Onboarding.stop3, location: 0.6),
            .init(color: Color.Onboarding.stop4, location: 0.9),
        ]
        return EllipticalGradient(
            gradient: Gradient(stops: colorStops),
            center: .topLeading,
            startRadiusFraction: -0.3,
            endRadiusFraction: 1.3
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
        .init(name: "Linear", style: .init(KleonGradient.linear())),
        .init(name: "Radial", style: .init(KleonGradient.radial())),
        .init(name: "Angular", style: .init(KleonGradient.angular())),
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
