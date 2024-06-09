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

            self.categoryGroupsBarData = SpendingTrendQueries.fetchCategoryGroupTrends(
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate,
                accountIds: accountIds
            )

            self.categoryGroupsLineData = SpendingTrendQueries.fetchLineMarks(
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate,
                accountIds: accountIds
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
            Money(
                minorUnitAmount: .init(rawAmount),
                currency: workspaceValues.budgetCurrency
            ).amountFormatted
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
