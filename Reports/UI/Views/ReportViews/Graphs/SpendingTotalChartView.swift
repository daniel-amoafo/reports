// Created by Daniel Amoafo on 21/4/2024.

import BudgetSystemService
import Charts
import ComposableArchitecture

import SwiftUI

struct SpendingTotalChartView: View {

    @Bindable var store: StoreOf<SpendingTotalChartFeature>
    @ScaledMetric(relativeTo: .body) private var breadcrumbChevronWidth: CGFloat = 5.0

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

private extension SpendingTotalChartView {

    var mainContent: some View {
        VStack(spacing: .Spacing.pt24) {
            titles

            chart

            Divider()

            categoryList
        }
    }

    var titles: some View {
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
        VStack(spacing: .Spacing.pt16) {
            Chart(store.selectedContent) { record in
                let highlight = store.selectedGraphItem == nil || record.id == store.selectedGraphItem?.id
                SectorMark(
                    angle: .value(Strings.chartValueKey, abs(record.total.amount)),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(20),
                    angularInset: 1
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value(Strings.chartNameKey, record.name))
                .opacity(highlight ? 1.0 : 0.4)
            }
            .chartAngleSelection(value: $store.rawSelectedGraphValue)
            .chartForegroundStyleScale(
                domain: store.chartNameColor.names,
                mapping: store.chartNameColor.colorFor
            )
            .scaledToFit()
            .chartOverlay { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack {
                            Text(store.selectedGraphItem?.name ?? store.totalName)
                                .typography(.title3Emphasized)
                                .foregroundStyle(Color.Text.secondary)
                            Text(store.selectedGraphItem?.total.amountFormatted ?? store.grandTotalValue)
                                .typography(.title2Emphasized)
                                .foregroundStyle(Color.Text.primary)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
        }
    }

    var categoryList: some View {
        CategoryListView(
            store: store.scope(state: \.categoryList, action: \.categoryList)
        )
    }

}

// MARK: -

private enum Strings {

    static let chartValueKey = String(
        localized: "Value",
        comment: "the key name used by voice over when reading chart values"
    )
    static let chartNameKey = String(
        localized: "Name",
        comment: "the key name used by voice over when reading the chart name"
    )
}

// MARK: -

#Preview {
    ScrollView {
        SpendingTotalChartView(
            store: .init(initialState: .withEntries) {
                SpendingTotalChartFeature()
            }
        )
    }
    .contentMargins(.Spacing.pt16)
    .background(Color.Surface.primary)
}

#Preview("No Results") {
    ZStack {
        Color.Surface.primary
            .ignoresSafeArea()
        SpendingTotalChartView(
            store: .init(initialState: .withNoEntries) {
                SpendingTotalChartFeature()
            }
        )
    }
}

extension SpendingTotalChartFeature.State {

    static var withEntries: Self {
        .init(
            title: "My Chart Name",
            budgetId: "Budget1",
            startDate: Date.distantPast.firstDayInMonth(),
            finishDate: .now.lastDayInMonth(),
            accountIds: "A1,A2,A3",
            categoryIds: "CAT-GROCERIES",
            transactionEntries: Shared(nil)
        )
    }

    static var withNoEntries: Self {
        .init(
            title: "",
            budgetId: "",
            startDate: Date.distantPast.firstDayInMonth(),
            finishDate: .now.lastDayInMonth(),
            accountIds: nil,
            categoryIds: nil,
            categoryGroups: [CategoryRecord](),
            transactionEntries: Shared(nil)
        )
    }
}
