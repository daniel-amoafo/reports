// Created by Daniel Amoafo on 13/5/2024.

import BudgetSystemService
import Charts
import ComposableArchitecture
import MoneyCommon
import SwiftUI

// MARK: - View

struct SpendingTrendChartView: View {

    @Bindable var store: StoreOf<SpendingTrendChartFeature>

    var body: some View {
        VStack(spacing: .Spacing.pt24) {
            titles

            chart

            Divider()

            categoryList
        }
    }

}

private extension SpendingTrendChartView {

    var titles: some View {
        VStack {
            Text(store.title)
                .typography(.title3Emphasized)
                .foregroundStyle(Color.Text.secondary)
        }
    }

    var chart: some View {
        Chart {
            ForEach(store.selectedContent) { barRecord in
                BarMark(
                    x: .value(Strings.xAxisLabel, barRecord.date, unit: .month),
                    y: .value(Strings.yAxisLabel, barRecord.total.amount)
                )
                .foregroundStyle(by: .value(Strings.nameLabel, barRecord.name))
            }

            ForEach(store.lineBarContent) { lineRecord in
                LineMark(
                    x: .value(Strings.xAxisLabel, lineRecord.date, unit: .month),
                    y: .value(Strings.yAxisLabel, lineRecord.total.amount)
                )
                .interpolationMethod(.cardinal(tension: 0.6))
                .foregroundStyle(Gradient.linear())

                // Outline
                PointMark(
                    x: .value("", lineRecord.date, unit: .month),
                    y: .value("", lineRecord.total.amount)
                )
                .foregroundStyle(Color.Line.stroke)
                .symbolSize(CGSize(width: 14, height: 14))

                // Fill
                PointMark(
                    x: .value("", lineRecord.date, unit: .month),
                    y: .value("", lineRecord.total.amount)
                )
                .foregroundStyle(Gradient.radial())
                .symbolSize(CGSize(width: 10, height: 10))

            }
        }
        .chartXAxis { xAxisMark }
        .chartYAxis { yAxisMark }
        .scaledToFit()
    }

    var categoryList: some View {
        CategoryListView(
            store: store.scope(state: \.categoryList, action: \.categoryList)
        )
    }

    var xAxisMark: AnyAxisContent {
        .init(
            AxisMarks { _ in
                AxisValueLabel(
                    format: .dateTime.year(.twoDigits).month(.twoDigits)
                )
            }
        )
    }

    var yAxisMark: AnyAxisContent {
        .init(
            AxisMarks { value in
                AxisGridLine()
                if let rawAmount = value.as(Int.self) {
                    AxisValueLabel(store.state.amountFormatted(for: rawAmount))
                }
            }
        )
    }

}

private enum Strings {

    static let xAxisLabel = String(localized: "Date", comment: "label for chart X axis values")

    static let yAxisLabel = String(localized: "Amount", comment: "label for chart Y axis values")

    static let nameLabel = String(localized: "Category", comment: "label for series value names")
}

// MARK: -

#Preview {
    ScrollView {
        SpendingTrendChartView(
            store: .init(
                initialState:
                        .init(
                            title: "My Chart Name",
                            budgetId: "Budget1",
                            fromDate: .distantPast.firstDayInMonth(),
                            toDate: .now.lastDayInMonth(),
                            accountIds: nil
                        )
            ) {
                SpendingTrendChartFeature()
            }
        )
    }
    .contentMargins(.Spacing.pt16)
    .background(Color.Surface.primary)
}
