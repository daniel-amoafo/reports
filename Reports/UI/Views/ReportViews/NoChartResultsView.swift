// Created by Daniel Amoafo on 30/6/2024.

import SwiftUI

struct NoChartResultsView: View {
    var body: some View {
        VStack(spacing: .Spacing.pt12) {
            Image(.searchNone)
                .resizable()
                .scaledToFit()
                .background(Color.Surface.secondary.gradient, in: .rect(cornerRadius: 12))
                .containerRelativeFrame(.horizontal) { length, _ in
                    length * 0.8
                }
            Text(Strings.noResults)
                .typography(.title3Emphasized)
        }
    }
}

private enum Strings {
    static let noResults =  String(localized: "No results found", comment: "")
}

#Preview {
    ZStack {
        Color.Surface.primary
            .ignoresSafeArea()
        NoChartResultsView()
    }
}
