// Created by Daniel Amoafo on 13/5/2024.

import BudgetSystemService
import Charts
import ComposableArchitecture
import MoneyCommon
import SwiftUI

// MARK: - View

struct SpendingTrendChartView: View {

    @Bindable var store: StoreOf<SpendingTrendChartFeature>
    @State var rawSelectedDate: Date?

    var body: some View {
        Group {
            if store.hasResults {
                mainContent
            } else {
                NoChartResultsView()
            }
        }
    }

}

private extension SpendingTrendChartView {

    var mainContent: some View {
        VStack(spacing: .Spacing.pt24) {
            headerTitles
            chart
            Divider()
            categoryList
        }
    }

    var headerTitles: some View {
        VStack {
            Text(store.title)
                .typography(.title3Emphasized)
                .foregroundStyle(Color.Text.secondary)
            Group {
                if let categoryName = store.maybeCategoryName {
                    Button {
                        store.send(.subTitleTapped, animation: .smooth)
                    } label: {
                        HStack {
                            Text("⬅️")
                            Text(categoryName)
                        }
                    }
                } else {
                    Text(store.listSubTitle)
                }
            }
            .font(Typography.subheadlineEmphasized.font)
            .foregroundStyle(Color.Text.primary)
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
                .foregroundStyle(Color.Line.stroke)

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
                .foregroundStyle(Color.Line.fill)
                .symbolSize(CGSize(width: 10, height: 10))
            }

            if let selectedDate {
                RuleMark(
                    x: .value("Selected", selectedDate, unit: .month)
                )
                .foregroundStyle(Color.gray.opacity(0.3))
                .offset(yStart: -10)
                .zIndex(-1)
                .annotation(
                    position: .top,
                    spacing: 0,
                    overflowResolution: .init(
                        x: .fit(to: .chart),
                        y: .disabled
                    )
                ) {
                    popoverRecordDetails(selectedDate)
                }
            }
        }
        .chartXAxis { xAxisMark }
        .chartYAxis { yAxisMark }
        .chartForegroundStyleScale(
            domain: store.chartNameColor.names,
            mapping: store.chartNameColor.colorFor
        )
        .scaledToFit()
        .chartXSelection(value: $rawSelectedDate)
    }

    var categoryList: some View {
        CategoryListView(
            store: store.scope(state: \.categoryList, action: \.categoryList)
        )
    }

}

// MARK: - Chart Components

private extension SpendingTrendChartView {

    var selectedDate: Date? {
        if let rawSelectedDate {
            return store.selectedContent.first(where: {
                let firstOfMonth = $0.date.firstDayInMonth()
                let lastOfMonth = $0.date.lastDayInMonth()

                return (firstOfMonth ... lastOfMonth).contains(rawSelectedDate)
            })?.date
        }
        return nil
    }

    @ViewBuilder
    func popoverRecordDetails(_ date: Date) -> some View {
        if let lineRecord = store.lineBarContent.first(where: {
               $0.date == date
           }) {
            VStack {
                Text("\(date.formatted(date: .abbreviated, time: .omitted))")
                Text("Bar \(store.state.popoverTotal(for: date))")
                Text("Line \(lineRecord.total.amountFormatted)")
            }
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(Color.gray.opacity(0.12))
            }
        }
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

// MARK: - Previews

#Preview {
    ScrollView {
        SpendingTrendChartView(store: .init(initialState: .withResults) {
            SpendingTrendChartFeature()
        })
    }
    .contentMargins(.Spacing.pt16)
    .background(Color.Surface.primary)
}

#Preview("No Results") {
    ZStack {
        Color.Surface.primary
            .ignoresSafeArea()
        SpendingTrendChartView(store: .init(initialState: .noResults) {
            SpendingTrendChartFeature()
        })
    }
}

private extension SpendingTrendChartFeature.State {

    static var withResults: Self {
        .init(
            title: "My Chart Name",
            budgetId: "Budget1",
            fromDate: .distantPast.firstDayInMonth(),
            toDate: .now.lastDayInMonth(),
            accountIds: nil,
            categoryIds: nil,
            transactionEntries: Shared(value: nil)
        )
    }

    static var noResults: Self {
        .init(
            title: "",
            budgetId: "",
            fromDate: .distantPast.firstDayInMonth(),
            toDate: .now.lastDayInMonth(),
            accountIds: nil,
            categoryIds: nil,
            transactionEntries: Shared(value: nil),
            categoryGroupsBar: [TrendRecord](),
            categoryGroupsLine: [TrendRecord]()
        )
    }
}
