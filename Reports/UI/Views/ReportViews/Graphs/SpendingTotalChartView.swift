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
        let title: String
        let startDate: Date
        let finishDate: Date
        var contentType: SpendingTotalChartFeature.ContentType = .categoryGroup

        var rawSelectedGraphValue: Decimal?
        var selectedGraphItem: CategoryRecord?

        fileprivate var categoryGroups: [CategoryRecord] = []

        // Categories for a given categoryGroup.
        // Updated when user selects a categoryGroup to inspect
        fileprivate var catgoriesForCategoryGroup: [CategoryRecord] = []
        fileprivate var catgoriesForCategoryGroupName: String?

        init(
            title: String,
            budgetId: String,
            startDate: Date,
            finishDate: Date
        ) {
            self.title = title
            self.startDate = startDate
            self.finishDate = finishDate

            self.categoryGroups = SpendingTotalQueries.fetchCategoryGroupTotals(
                budgetId: budgetId, startDate: startDate, finishDate: finishDate
            )
        }

        var selectedContent: [CategoryRecord] {
            switch contentType {
            case .categoryGroup:
                return categoryGroups
            case .categoriesByCategoryGroup:
                return catgoriesForCategoryGroup
            }
        }

        var totalName: String {
            switch contentType {
            case .categoryGroup:
                return Strings.allCategoriesTitle
            case .categoriesByCategoryGroup:
                return String(format: Strings.categoryNameTotal, (catgoriesForCategoryGroupName ?? ""))
            }
        }

        var grandTotalValue: String {
            let selected = selectedContent
            guard let currency = selected.first?.total.currency else {
                return ""
            }
            // tally up all the totals for each record to provide a grand total
            let total = selected.map(\.total).reduce(.zero(currency), +)
            return total.amountFormatted
        }

        var listSubTitle: String {
            switch contentType {
            case .categoryGroup, .categoriesByCategoryGroup:
                return Strings.allCategoriesTitle
            }
        }

        var isDisplayingSubCategory: Bool {
            contentType == .categoriesByCategoryGroup
        }

        var maybeCategoryName: String? {
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
        case delegate(Delegate)
        case listRowTapped(id: String)
        case catgoriesForCategoryGroupFetched([CategoryRecord], String)
        case subTitleTapped
        case onAppear

        @CasePathable
        enum Delegate {
            case categoryTapped(IdentifiedArrayOf<TransactionEntry>)
        }
    }

    enum ContentType: Equatable {
        case categoryGroup
        case categoriesByCategoryGroup
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.database.grdb) var grdb

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.rawSelectedGraphValue):
                guard let rawSelected = state.rawSelectedGraphValue else {
                    state.selectedGraphItem = nil
                    return .none
                }
                var cumulative = Decimal.zero
                // This approach is lifted from Apple's interactive pie chart WWDC talk
                // see https://developer.apple.com/wwdc23/10037
                let cumulativeArea = state.selectedContent.map {
                    let newCumulative = cumulative + abs($0.total.amount)
                    let result = (id: $0.id, range: cumulative ..< newCumulative)
                    cumulative = newCumulative
                    return result
                }

                guard let foundEntry = cumulativeArea
                    .first(where: { $0.range.contains(rawSelected) }),
                      let item = state.selectedContent.first(where: { $0.id == foundEntry.id })
                else { return .none }
                state.selectedGraphItem = item
                return .none

            case let .catgoriesForCategoryGroupFetched(records, categoryGroupName):
                state.catgoriesForCategoryGroup = records
                state.catgoriesForCategoryGroupName = categoryGroupName
                state.contentType = .categoriesByCategoryGroup
                state.selectedGraphItem = nil
                return .none

            case let .listRowTapped(id):
                switch state.contentType {
                case .categoryGroup:
                    let (records, groupName) = SpendingTotalQueries.fetchCategoryTotals(
                        categoryGroupId: id,
                        startDate: state.startDate,
                        finishDate: state.finishDate
                    )
                    return .send(.catgoriesForCategoryGroupFetched(records, groupName), animation: .smooth)

                case .categoriesByCategoryGroup:
                    let transactions = SpendingTotalQueries.fetchTransactionEntries(
                        for: id,
                        startDate: state.startDate,
                        finishDate: state.finishDate
                    )
                    return .send(.delegate(.categoryTapped(transactions)), animation: .smooth)
                }

            case .subTitleTapped:
                state.contentType = .categoryGroup
                state.catgoriesForCategoryGroup = []
                state.catgoriesForCategoryGroupName = nil
                state.selectedGraphItem = nil
                return .none

            case .onAppear:
                return .none

            case .binding,
                    .delegate:
                return .none
            }
        }
    }
}

/// Manages calls to Database queries
private enum SpendingTotalQueries {

    static let logger = LogFactory.create(category: String(describing: SpendingTotalQueries.self))

    static var grdb: GRDBDatabase {
        @Dependency(\.database.grdb) var grdb
        return grdb
    }

    static func fetchCategoryGroupTotals(budgetId: String, startDate: Date, finishDate: Date) -> [CategoryRecord] {
        do {
            let categoryGroupBuilder = CategoryRecord
                .queryTransactionsByCategoryGroupTotals(
                    budgetId: budgetId,
                    startDate: startDate,
                    finishDate: finishDate
                )

            return try grdb.fetchRecords(builder: categoryGroupBuilder)
        } catch {
            logger.error("\(String(describing: error))")
            return []
        }
    }

    static func fetchCategoryTotals(
        categoryGroupId: String,
        startDate: Date,
        finishDate: Date
    ) -> ([CategoryRecord], String) {
        do {
            let categoryBuilder = CategoryRecord
                .queryTransactionsByCategoryTotals(
                    forCategoryGroupId: categoryGroupId,
                    startDate: startDate,
                    finishDate: finishDate
                )
            let records = try Self.grdb.fetchRecords(builder: categoryBuilder)

            let groupName = try CategoryGroup.fetch(id: categoryGroupId)?.name ?? ""

            return (records, groupName)
        } catch {
            Self.logger.error("\(error.toString())")
            return ([], "")
        }
    }

    static func fetchTransactionEntries(for categoryId: String, startDate: Date, finishDate: Date)
    -> IdentifiedArrayOf<TransactionEntry> {
        do {
            let transactionsBuilder = TransactionEntry.queryTransactionsByCategoryId(
                categoryId,
                startDate: startDate,
                finishDate: finishDate
            )
            let transactions = try Self.grdb.fetchRecords(builder: transactionsBuilder)

            return .init(uniqueElements: transactions)
        } catch {
            Self.logger.error("\(error.toString())")
            return .init(uniqueElements: [])
        }
    }

}

// MARK: - View

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
                    Text(Strings.allCategoriesTitle)
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
    static let allCategoriesTitle = String(
        localized: "All Categories",
        comment: "The collective name for top level category groups"
    )
    static let categoryNameTotal = String(
        localized: "%@ Total",
        comment: "A category total. %@ = The selected category "
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
                        finishDate: .now.lastDayInMonth()
                    )
            ) {
                 SpendingTotalChartFeature()
            }
        )
    }
    .contentMargins(.Spacing.pt16)
    .background(Color.Surface.primary)
}
