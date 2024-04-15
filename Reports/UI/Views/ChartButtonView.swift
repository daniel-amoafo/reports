// Created by Daniel Amoafo on 13/4/2024.

import SwiftUI

struct ChartButtonView: View {

    let title: String
    let image: Image
    let action: () -> Void

    // Scale button size to the devices DynamicType size
    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 72
    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 118
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 166

    private let maxWidth: CGFloat = 250
    private let maxHieght: CGFloat = 351

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSize)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)

                    Text(title)
                        .typography(.headlineEmphasized)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.Spacing.small)
            }
            .frame(width: min(width, 250), height: min(height, 351))
            .backgroundShadow()
        }
        .buttonStyle(.plain)
    }

}

#Preview("Single Chart") {
    ChartButtonView(title: "Title Goes Here", image: ChartType.pie.image) {}
}

#Preview("All Charts") {
    ScrollView(.horizontal) {
        HStack(spacing: .Spacing.medium) {
            ForEach(Chart.makeDefaultCharts()) { chart in
                ChartButtonView(title: chart.name, image: chart.type.image) {
                    // perform button action here
                }
            }
        }
        .padding()
    }
    .padding()
}
