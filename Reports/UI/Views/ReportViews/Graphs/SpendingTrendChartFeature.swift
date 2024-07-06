// Created by Daniel Amoafo on 5/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import MoneyCommon

@Reducer
struct SpendingTrendChartFeature {

    @ObservableState
    struct State: Equatable {
        let title: String
        let budgetId: String
        let fromDate: Date
        let toDate: Date
        let accountIds: String?
        var contentType: CategoryType = .group
        var categoryList: CategoryListFeature.State = .empty
        var categoryGroupName: String?

        @Shared(.workspaceValues) var workspaceValues
        fileprivate let categoryGroupsBarData: [TrendRecord]
        fileprivate let categoryGroupsLineData: [TrendRecord]
        fileprivate let categoryGroupsChartNameColors: ChartNameColor

        // Categories for a given categoryGroup.
        // Updated when user selects a categoryGroup to inspect
        fileprivate var categoriesByCategoryGroupBars: [TrendRecord] = []
        fileprivate var categoriesByCategoryGroupName: String?
        fileprivate var categoriesByCategoryGroupLines: [TrendRecord] = []
        fileprivate var categoriesByCategoryGroupChartNameColors = ChartNameColor(names: [])

        init(
            title: String,
            budgetId: String,
            fromDate: Date,
            toDate: Date,
            accountIds: String?,
            categoryGroupsBar: [TrendRecord]? = nil,
            categoryGroupsLine: [TrendRecord]? = nil
        ) {
            self.title = title
            self.budgetId = budgetId
            self.fromDate = fromDate
            self.toDate = toDate
            self.accountIds = accountIds

            self.categoryGroupsBarData = if let categoryGroupsBar {
                categoryGroupsBar
            } else {
                SpendingTrendQueries.fetchTrends(
                    budgetId: budgetId,
                    fromDate: fromDate,
                    toDate: toDate,
                    accountIds: accountIds
                )
            }

            self.categoryGroupsChartNameColors = .init(
                names: categoryGroupsBarData.map(\.name)
            )

            self.categoryGroupsLineData = if let categoryGroupsLine {
                categoryGroupsLine
            } else {
                SpendingTrendQueries.fetchLineMarks(
                    budgetId: budgetId,
                    fromDate: fromDate,
                    toDate: toDate,
                    accountIds: accountIds
                )
            }

            let categoryListItems = fetchCategoryListGroupTotals()
            self.categoryList = makeCategoryListFeatureState(
                items: categoryListItems,
                chartNameColor: categoryGroupsChartNameColors
            )
        }

        var hasResults: Bool {
            categoryGroupsBarData.isNotEmpty
        }

        func fetchCategoryListGroupTotals() -> [CategoryRecord] {
            CategoryListQueries.fetchCategoryGroupTotals(
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate,
                accountIds: accountIds
            )
        }

        func makeCategoryListFeatureState(items: [any CategoryListItem], chartNameColor: ChartNameColor)
        -> CategoryListFeature.State {
            .init(
                contentType: contentType,
                fromDate: fromDate,
                toDate: toDate,
                listItems: items.map(AnyCategoryListItem.init),
                categoryGroupName: categoryGroupName,
                chartNameColor: chartNameColor
            )
        }

        var selectedContent: [TrendRecord] {
            switch contentType {
            case .group:
                return categoryGroupsBarData
            case .subCategories:
                return categoriesByCategoryGroupBars
            }
        }

        var maybeCategoryName: String? {
            switch contentType {
            case .group:
                return nil
            case .subCategories:
                return categoryGroupName
            }
        }

        var lineBarContent: [TrendRecord] {
            switch contentType {
            case .group:
                return categoryGroupsLineData
            case .subCategories:
                return categoriesByCategoryGroupLines
            }
        }

        func amountFormatted(for rawAmount: Int) -> String {
            return Money(
                majorUnitAmount: .init(rawAmount),
                currency: workspaceValues.budgetCurrency
            ).amountFormatted(
                formatter: .abbreviated(
                    signOption: .none,
                    threshold: -1_000_000_000_000
                ),
                for: .current
            )
        }

        var chartNameColor: ChartNameColor {
            switch contentType {
            case .group:
                return categoryGroupsChartNameColors

            case .subCategories:
                return categoriesByCategoryGroupChartNameColors
            }
        }

    }

    enum Action {
        case subTitleTapped
        case categoryList(CategoryListFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.categoryList, action: \.categoryList) {
            CategoryListFeature()
        }
        Reduce { state, action in
            switch action {
            case let .categoryList(.delegate(.categoryGroupTapped(id))):
                let (records, groupName) = SpendingTrendQueries.fetchTrendsForGroupId(
                    categoryGroupId: id,
                    fromDate: state.fromDate,
                    toDate: state.toDate,
                    accountIds: state.accountIds
                )
                let lineRecords = SpendingTrendQueries.fetchLineMarksForGroupId(
                    categoryGroupId: id,
                    fromDate: state.fromDate,
                    toDate: state.toDate,
                    accountIds: state.accountIds
                )
                let (categoryListItems, _) = CategoryListQueries.fetchCategoryTotals(
                    categoryGroupId: id,
                    fromDate: state.fromDate,
                    toDate: state.toDate,
                    accountIds: state.accountIds
                )
                let chartNameColors: ChartNameColor = .init(names: records.map(\.name))

                state.categoriesByCategoryGroupBars = records
                state.categoryGroupName = groupName
                state.categoriesByCategoryGroupLines = lineRecords
                state.categoriesByCategoryGroupChartNameColors = chartNameColors
                state.contentType = .subCategories
                state.categoryList = state
                    .makeCategoryListFeatureState(
                        items: categoryListItems,
                        chartNameColor: chartNameColors
                    )
                return .none

            case .subTitleTapped, .categoryList(.delegate(.subTitleTapped)):
                state.contentType = .group
                state.categoriesByCategoryGroupBars = []
                state.categoriesByCategoryGroupName = nil
                let categoryListItems = state.fetchCategoryListGroupTotals()
                state.categoryList = state.makeCategoryListFeatureState(
                    items: categoryListItems,
                    chartNameColor: state.categoryGroupsChartNameColors
                )
                return .none

            case .categoryList:
                return .none
            }
        }
    }
}

// MARK: -

/// Manages calls to Database queries
private enum SpendingTrendQueries {

    static let logger = LogFactory.create(Self.self)

    static var grdb: GRDBDatabase {
        @Dependency(\.database.grdb) var grdb
        return grdb
    }

    static func fetchTrends(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> [TrendRecord] {
        do {
            let sqlBuilder = TrendRecord
                .queryBySpendingTrendsBarMarks(
                    budgetId: budgetId,
                    fromDate: fromDate,
                    toDate: toDate,
                    accountIds: accountIds
                )

            return try grdb.fetchRecords(builder: sqlBuilder)
        } catch {
            logger.error("\(String(describing: error))")
            return []
        }
    }

    static func fetchTrendsForGroupId(
        categoryGroupId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> ([TrendRecord], String) {
        do {
            let sqlBuilder = TrendRecord
                .queryBySpendingTrendsBarMarks(
                    categoryGroupId: categoryGroupId,
                    fromDate: fromDate,
                    toDate: toDate,
                    accountIds: accountIds
                )

            let records = try Self.grdb.fetchRecords(builder: sqlBuilder)

            let groupName = try CategoryGroup.fetch(id: categoryGroupId)?.name ?? ""

            return (records, groupName)

        } catch {
            logger.error("\(String(describing: error))")
            return ([], "")
        }
    }

    // MARK: - Line Marks Data

    static func fetchLineMarks(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> [TrendRecord] {
        do {
            let sqlBuilder = TrendRecord.queryBySpendingTrendsLineMarks(
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate,
                accountIds: accountIds
            )

            return try grdb.fetchRecords(builder: sqlBuilder)
        } catch {
            logger.error("\(String(describing: error))")
            return []
        }
    }

    static func fetchLineMarksForGroupId(
        categoryGroupId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> [TrendRecord] {
        do {
            let sqlBuilder = TrendRecord.queryBySpendingTrendsLineMarks(
                categoryGroupId: categoryGroupId,
                fromDate: fromDate,
                toDate: toDate,
                accountIds: accountIds
            )

            return try grdb.fetchRecords(builder: sqlBuilder)
        } catch {
            logger.error("\(String(describing: error))")
            return []
        }
    }

}
