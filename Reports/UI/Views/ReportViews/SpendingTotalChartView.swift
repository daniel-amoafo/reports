// Created by Daniel Amoafo on 21/4/2024.

import BudgetSystemService
import Charts
import ComposableArchitecture
import MoneyCommon
import SwiftUI

// MARK: - Reducer

@Reducer
struct SpendingTotalChartFeature {

    @ObservableState
    struct State: Equatable {
        let transactions: IdentifiedArrayOf<TransactionEntry>
        var contentType: SpendingTotalChartFeature.ContentType

        var rawSelectedGraphValue: Decimal?

        // Populated at initialization
        fileprivate let categoryGroups: IdentifiedArrayOf<TabulatedDataItem>
        fileprivate let categories: IdentifiedArrayOf<TabulatedDataItem>

        // Categories for a given categoryGroup.
        // Updated when user selects a categoryGroup to inspect
        fileprivate var catgoriesForCategoryGroup: IdentifiedArrayOf<TabulatedDataItem> = []
        fileprivate var catgoriesForCategoryGroupName: String?

        init(
            transactions: IdentifiedArrayOf<TransactionEntry>,
            contentType: SpendingTotalChartFeature.ContentType = .categoryGroup
        ) {
            self.transactions = transactions
            self.contentType = contentType
            let (groups, categories) = TabulatedDataItem.makeCategoryValues(transactions: transactions)
            self.categoryGroups = groups
            self.categories = categories
        }

        var selectedContent: IdentifiedArrayOf<TabulatedDataItem> {
            switch contentType {
            case .categoryGroup:
                return categoryGroups
            case .categoriesByCategoryGroup:
                return catgoriesForCategoryGroup
            }
        }

        var listSubTitle: String {
            switch contentType {
            case .categoryGroup, .categoriesByCategoryGroup:
                return Strings.listSubTitleAllCategories
            }
        }

        var isListSubTitleALink: Bool {
            contentType == .categoriesByCategoryGroup
        }

        var listBreadcrumbTitle: String? {
            switch contentType {
            case .categoryGroup:
                return nil
            case .categoriesByCategoryGroup:
                return catgoriesForCategoryGroupName
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case entryTapped(id: String)
        case listSubTitleTapped
    }

    enum ContentType: Equatable {
        case categoryGroup
        case categoriesByCategoryGroup
    }

    @Dependency(\.budgetClient) var budgetClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.rawSelectedGraphValue):
                guard let rawSelected = state.rawSelectedGraphValue else { return .none }
                var cumulative = Decimal.zero
                // This approach is lifted from apple example interactive pie chart talk
                // see https://developer.apple.com/wwdc23/10037
                let cumulativeArea = state.selectedContent.map {
                    let newCumulative = cumulative + abs($0.value)
                    let result = (id: $0.id, range: cumulative ..< newCumulative)
                    cumulative = newCumulative
                    return result
                }

                guard let foundEntry = cumulativeArea
                    .first(where: { $0.range.contains(rawSelected) }) else { return .none }

                return .run { send in
                    await send(.entryTapped(id: foundEntry.id))
                }
            case .binding:
                return .none
            case let .entryTapped(id):
                switch state.contentType {
                case .categoryGroup:
                    // filter displaying categories for the selected Category Group
                    guard let group = budgetClient.getCategoryGroup(groupId: id) else {
                        return .none
                    }
                    // sort entries with the most spent categories taking precedence
                    var items = state.categories
                        .filter { group.categoryIds.contains($0.id) }
                    items.sort { $0.value < $1.value }
                    state.catgoriesForCategoryGroup = items
                    state.catgoriesForCategoryGroupName = group.name
                    state.contentType = .categoriesByCategoryGroup

                case .categoriesByCategoryGroup:
                    // drill down t
                    state.catgoriesForCategoryGroup = []
                    state.catgoriesForCategoryGroupName = nil
                    state.contentType = .categoryGroup
                }
                return .none
            case.listSubTitleTapped:
                state.contentType = .categoryGroup
                state.catgoriesForCategoryGroup = []
                return .none
            }
        }
    }
}

// MARK: - View

struct SpendingTotalChartView: View {

    @Bindable var store: StoreOf<SpendingTotalChartFeature>
    @ScaledMetric(relativeTo: .body) private var breadcrumbChevronWidth: CGFloat = 5.0

    var body: some View {
        VStack(spacing: .Spacing.pt24) {
            chart

            Divider()

            listRows
        }
    }

    private var chart: some View {
        VStack(spacing: .Spacing.pt16) {
            Chart(store.selectedContent) { item in
                SectorMark(
                    angle: .value(Strings.chartValueKey, abs(item.value)),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(20),
                    angularInset: 1
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value(Strings.chartNameKey, item.name))
            }
            .chartLegend(.visible)
            .chartLegend(alignment: .bottom)
            .scaledToFit()
            .chartAngleSelection(value: $store.rawSelectedGraphValue)
        }
    }

    private var listRows: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text(Strings.categorized)
                        .typography(.title2Emphasized)
                        .foregroundStyle(Color(R.color.text.secondary))
                    Spacer()
                }
                HStack {
                    Text(store.listSubTitle)
                        .typography(store.isListSubTitleALink ? .bodyEmphasized : .body)
                        .foregroundStyle(
                            store.isListSubTitleALink ? Color(R.color.text.link) : Color(R.color.text.secondary)
                        )
                        .underline(store.isListSubTitleALink)
                        .onTapGesture {
                            if store.isListSubTitleALink {
                                store.send(.listSubTitleTapped, animation: .default)
                            }
                        }
                        .accessibilityAddTraits(store.isListSubTitleALink ? .isButton : [])
                        .accessibilityAction {
                            if store.isListSubTitleALink {
                                store.send(.listSubTitleTapped, animation: .default)
                            }
                        }
                    if let breadcrumbTitle = store.listBreadcrumbTitle {
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: breadcrumbChevronWidth)
                            .foregroundStyle(Color(R.color.icon.secondary))
                        Text(breadcrumbTitle)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color(R.color.text.primary))
                    }
                    Spacer()
                }
            }
            .listRowTop()

            // Category rows
            ForEach(store.selectedContent) { item in
                Button {
                    store.send(.entryTapped(id: item.id), animation: .default)
                } label: {
                    HStack {
                        Text(item.name)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color(R.color.text.primary))
                        Spacer()
                        Text(item.valueFormatted)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color(R.color.text.primary))
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
}

// MARK: -

private enum Strings {

    static let categorized = String(
        localized: "Categories",
        comment: "title for list of categories for the selected data set"
    )
    static let listSubTitleAllCategories = String(
        localized: "All Categories",
        comment: "The collective name for top level category groups"
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
                initialState: .init(transactions: .mocks),
                reducer: { SpendingTotalChartFeature() }
            )
        )
    }
    .contentMargins(.Spacing.pt16)
}
