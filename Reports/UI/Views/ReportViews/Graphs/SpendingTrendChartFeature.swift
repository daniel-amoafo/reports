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
        var categoryList: CategoryListFeature.State
        var categoriesForCategoryGroupName: String?

        @Shared(.wsValues) var workspaceValues
        fileprivate let categoryGroupsBarData: [TrendRecord]
        fileprivate let categoryGroupsLineData: [TrendRecord]

        // Categories for a given categoryGroup.
        // Updated when user selects a categoryGroup to inspect
        fileprivate var categoriesByCategoryGroupBars: [TrendRecord] = []
        fileprivate var categoriesByCategoryGroupName: String?
        fileprivate var categoriesByCategoryGroupLines: [TrendRecord] = []

        init(title: String, budgetId: String, fromDate: Date, toDate: Date, accountIds: String?) {
            self.title = title
            self.budgetId = budgetId
            self.fromDate = fromDate
            self.toDate = toDate
            self.accountIds = accountIds

            let groupsBarData = SpendingTrendQueries.fetchCategoryGroupTrends(
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate,
                accountIds: accountIds
            )
            self.categoryGroupsBarData = groupsBarData

            self.categoryGroupsLineData = SpendingTrendQueries.fetchLineMarks(
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate,
                accountIds: accountIds
            )

            // dummy values to satisfy all stored values before
            self.categoryList = .init(
                contentType: .group,
                fromDate: .distantPast,
                toDate: .distantFuture,
                listItems: []
            )
            self.categoryList = makeCategoryListFeatureState(items: groupsBarData)

        }

        func makeCategoryListFeatureState(items: [TrendRecord])
        -> CategoryListFeature.State {
            .init(
                contentType: contentType,
                fromDate: fromDate,
                toDate: toDate,
                listItems: items.map(AnyCategoryListItem.init)
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
            ).amountFormattedAbbreviated
        }
    }

    enum Action {
        case categoryList(CategoryListFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.categoryList, action: \.categoryList) {
            CategoryListFeature()
        }
        Reduce { state, action in
            switch action {
            case let .categoryList(.delegate(.categoryGroupTapped(id))):
                debugPrint(id)
                return .none

            case .categoryList(.delegate(.subTitleTapped)):
                state.contentType = .group
                state.categoriesByCategoryGroupBars = []
                state.categoriesByCategoryGroupName = nil
                state.categoryList = state.makeCategoryListFeatureState(items: state.categoryGroupsBarData)
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

    static func fetchCategoryGroupTrends(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> [TrendRecord] {
        do {
            let categoryGroupBuilder = TrendRecord
                .queryBySpendingTrendsCategoryGroup(
                    budgetId: budgetId,
                    fromDate: fromDate,
                    toDate: toDate,
                    accountIds: accountIds
                )

            return try grdb.fetchRecords(builder: categoryGroupBuilder)
        } catch {
            logger.error("\(String(describing: error))")
            return []
        }
    }

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
}
