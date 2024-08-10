// Created by Daniel Amoafo on 5/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import MoneyCommon

enum CategoryType: Equatable, Sendable {
    case group
    case subCategories
}
// this is a really long long this is a really long long this is a really long long this is a really long long this is a really long long
@Reducer
struct SpendingTotalChartFeature {

    @ObservableState
    struct State: Equatable {
        let title: String
        let startDate: Date
        let finishDate: Date
        let accountIds: String?
        let categoryIds: String?
        var contentType: CategoryType = .group
        var categoryList: CategoryListFeature.State = .empty
        var rawSelectedGraphValue: Decimal?
        var selectedGraphItem: CategoryRecord?
        @Shared var transactionEntries: [TransactionEntry]?

        fileprivate let categoryGroups: [CategoryRecord]
        fileprivate let categoryGroupsChartNameColors: ChartNameColor

        // Categories for a given categoryGroup.
        // Updated when user selects a categoryGroup to inspect
        fileprivate var catgoriesForCategoryGroup: [CategoryRecord] = []
        fileprivate var categoriesForCategoryGroupName: String?
        fileprivate var categoriesByCategoryGroupChartNameColors = ChartNameColor(names: [])

        init(
            title: String,
            budgetId: String,
            startDate: Date,
            finishDate: Date,
            accountIds: String?,
            categoryIds: String?,
            categoryGroups: [CategoryRecord]? = nil,
            transactionEntries: Shared<[TransactionEntry]?>
        ) {
            self.title = title
            self.startDate = startDate
            self.finishDate = finishDate
            self.accountIds = accountIds
            self.categoryIds = categoryIds
            self._transactionEntries = transactionEntries

            self.categoryGroups = if let categoryGroups {
                categoryGroups
            } else {
                CategoryListQueries.fetchCategoryGroupTotals(
                    budgetId: budgetId,
                    fromDate: startDate,
                    toDate: finishDate,
                    accountIds: accountIds,
                    categoryIds: categoryIds
                )
            }

            let chartNameColor = ChartNameColor(names: self.categoryGroups.map(\.name))
            self.categoryGroupsChartNameColors = chartNameColor
            self.categoryList = makeCategoryListFeatureState(
                items: self.categoryGroups,
                chartNameColor: chartNameColor
            )
        }

        var hasResults: Bool {
            categoryGroups.isNotEmpty
        }

        var selectedContent: [CategoryRecord] {
            switch contentType {
            case .group:
                return categoryGroups
            case .subCategories:
                return catgoriesForCategoryGroup
            }
        }

        var totalName: String {
            switch contentType {
            case .group:
                return categorySelectionMode.title
            case .subCategories:
                return String(format: Strings.categoryNameTotal, (categoriesForCategoryGroupName ?? ""))
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
            categorySelectionMode.title
        }

        var isDisplayingSubCategory: Bool {
            contentType == .subCategories
        }

        var maybeCategoryName: String? {
            switch contentType {
            case .group:
                return nil
            case .subCategories:
                return categoriesForCategoryGroupName
            }
        }

        var chartNameColor: ChartNameColor {
            switch contentType {
            case .group:
                return categoryGroupsChartNameColors

            case .subCategories:
                return categoriesByCategoryGroupChartNameColors
            }
        }

        var categorySelectionMode: CategoryListFeature.CategorySelectionMode {
            categoryIds == nil ? .all : .some
        }

        func makeCategoryListFeatureState(
            items: [any CategoryListItem],
            chartNameColor: ChartNameColor,
            groupName: String? = nil
        )
        -> CategoryListFeature.State {
            .init(
                contentType: contentType,
                fromDate: startDate,
                toDate: finishDate,
                listItems: items.map(AnyCategoryListItem.init),
                categoryGroupName: groupName,
                chartNameColor: chartNameColor,
                categorySelectionMode: categorySelectionMode,
                transactionEntries: $transactionEntries
            )
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case categoryList(CategoryListFeature.Action)
        case subTitleTapped
    }

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.categoryList, action: \.categoryList) {
            CategoryListFeature()
        }
        Reduce<State, Action> { state, action in
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

            case let .categoryList(.delegate(.categoryGroupTapped(id))):
                let (records, groupName) = SpendingTotalQueries.fetchCategoryTotals(
                    categoryGroupId: id,
                    startDate: state.startDate,
                    finishDate: state.finishDate,
                    accountIds: state.accountIds,
                    categoryIds: state.categoryIds
                )
                let chartNameColor = ChartNameColor(names: records.map(\.name))
                state.catgoriesForCategoryGroup = records
                state.categoriesForCategoryGroupName = groupName
                state.contentType = .subCategories
                state.selectedGraphItem = nil
                state.categoriesByCategoryGroupChartNameColors = chartNameColor
                state.categoryList = state.makeCategoryListFeatureState(
                    items: records,
                    chartNameColor: chartNameColor,
                    groupName: groupName
                )
                return .none

            case .subTitleTapped, .categoryList(.delegate(.subTitleTapped)):
                state.contentType = .group
                state.catgoriesForCategoryGroup = []
                state.categoriesForCategoryGroupName = nil
                state.selectedGraphItem = nil
                state.categoryList = state.makeCategoryListFeatureState(
                    items: state.categoryGroups,
                    chartNameColor: state.categoryGroupsChartNameColors
                )
                return .none

            case .binding, .categoryList:
                return .none
            }
        }
    }
}

// MARK: -

/// Manages calls to Database queries
private enum SpendingTotalQueries {

    static let logger = LogFactory.create(Self.self)

    static var grdb: GRDBDatabase {
        @Dependency(\.database.grdb) var grdb
        return grdb
    }

    static func fetchCategoryTotals(
        categoryGroupId: String,
        startDate: Date,
        finishDate: Date,
        accountIds: String?,
        categoryIds: String?
    ) -> ([CategoryRecord], String) {
        do {
            let categoryBuilder = CategoryRecord
                .queryTransactionsByCategoryTotals(
                    forCategoryGroupId: categoryGroupId,
                    startDate: startDate,
                    finishDate: finishDate,
                    accountIds: accountIds,
                    categoryIds: categoryIds
                )
            let records = try Self.grdb.fetchRecords(builder: categoryBuilder)

            let groupName = try CategoryGroup.fetch(id: categoryGroupId)?.name ?? ""

            return (records, groupName)
        } catch {
            Self.logger.error("\(error.toString())")
            return ([], "")
        }
    }
}

// MARK: -

private enum Strings {

    static let categoryNameTotal = String(
        localized: "%@ Total",
        comment: "A category total. %@ = The selected category"
    )

}
