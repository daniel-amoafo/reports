// Created by Daniel Amoafo on 21/4/2024.

import BudgetSystemService
import Charts
import ComposableArchitecture

import SwiftUI

struct SpendingTotalChartView: View {

    @Bindable var store: StoreOf<SpendingTotalChartFeature>
    @ScaledMetric(relativeTo: .body) private var breadcrumbChevronWidth: CGFloat = 5.0

    // Default colors & ordering used in Apple Charts. This array is used to map the category colors
    // in the chart to the entries displayed in the list.
    private let colors = [Color.blue, .green, .orange, .purple, .red, .cyan, .yellow]

    var body: some View {
        VStack(spacing: .Spacing.pt24) {
            titles

            chart

            Divider()

            listRows
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var titles: some View {
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
                    Text(AppStrings.allCategoriesTitle)
                }
            }
            .font(Typography.subheadlineEmphasized.font)
            .foregroundStyle(Color.Text.primary)

        }
    }

    private var chart: some View {
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
            .chartLegend()
            .scaledToFit()
            .chartAngleSelection(value: $store.rawSelectedGraphValue)
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

    private var listRows: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text(Strings.categorized)
                        .typography(.title2Emphasized)
                        .foregroundStyle(Color.Text.secondary)
                    Spacer()
                }
                HStack {
                    Text(store.listSubTitle)
                        .typography(.bodyEmphasized)
                        .foregroundStyle(
                            store.isDisplayingSubCategory ? Color.Text.link : Color.Text.secondary
                        )
                        .onTapGesture {
                            if store.isDisplayingSubCategory {
                                store.send(.subTitleTapped, animation: .default)
                            }
                        }
                        .accessibilityAddTraits(store.isDisplayingSubCategory ? .isButton : [])
                        .accessibilityAction {
                            if store.isDisplayingSubCategory {
                                store.send(.subTitleTapped, animation: .default)
                            }
                        }
                    if let breadcrumbTitle = store.maybeCategoryName {
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: breadcrumbChevronWidth)
                            .foregroundStyle(Color.Icon.secondary)
                        Text(breadcrumbTitle)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color.Text.primary)
                    }
                    Spacer()
                }
            }
            .listRowTop()

            // Category rows
            ForEach(store.selectedContent) { record in
                Button {
                    store.send(.listRowTapped(id: record.id), animation: .default)
                } label: {
                    HStack {
                        BasicChartSymbolShape.circle
                            .foregroundStyle(colorFor(record))
                            .frame(width: 8, height: 8)
                        Text(record.name)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color.Text.primary)
                        Spacer()
                        Text(record.total.amountFormatted)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color.Text.primary)
                    }
                }
                .buttonStyle(.listRow)
            }

            // Footer row
            Text("")
                .listRowBottom()
        }
        .backgroundShadow()
    }

    // Colors are mapped using Apple chart ordering
    private func colorFor(_ record: CategoryRecord) -> Color {
        let index = store.selectedContent.firstIndex(of: record) ?? 0
        return colors[index % colors.count]
    }

}

// MARK: -

private enum Strings {

    static let categorized = String(
        localized: "Categories",
        comment: "title for list of categories for the selected data set"
    )

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
            store: .init(
                initialState:
                    .init(
                        title: "My Chart Name",
                        budgetId: "Budget1",
                        startDate: .now.firstDayInMonth(),
                        finishDate: .now.lastDayInMonth(),
                        accountIds: nil
                    )
            ) {
                 SpendingTotalChartFeature()
            }
        )
    }
    .contentMargins(.Spacing.pt16)
    .background(Color.Surface.primary)
}
