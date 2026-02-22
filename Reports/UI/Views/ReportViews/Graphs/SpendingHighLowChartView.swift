// Created by Daniel Amoafo on 19/1/2025.

import Charts
import ComposableArchitecture
import SwiftUI

struct SpendingHighLowChartView: View {

    @Bindable var store: StoreOf<SpendingHighLowChartFeature>

    var body: some View {
        mainContent
    }
}

private extension SpendingHighLowChartView {

    var mainContent: some View {
        VStack(spacing: .Spacing.pt24) {
            title
        }
    }

    var title: some View {
        GraphTitleView(
            title: store.title,
            listSubTitle: "",
            selected: nil
        )
    }
}

#Preview {

    ScrollView {
        SpendingHighLowChartView(store: .init(initialState: .withResults) {
            SpendingHighLowChartFeature()
        })
    }
    .contentMargins(.Spacing.pt16)
    .background(Color.Surface.primary)
}

private extension SpendingHighLowChartFeature.State {

    static var withResults: Self {
        .init(
            title: "My High Low Chart",
            budgetId: "Budget1",
            fromDate: .distantPast.firstDayInMonth(),
            toDate: .now.lastDayInMonth(),
            accountIds: nil
        )
    }
}
