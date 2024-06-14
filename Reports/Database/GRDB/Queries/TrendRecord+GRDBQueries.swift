// Created by Daniel Amoafo on 6/6/2024.

import Foundation

// swiftlint:disable line_length

extension TrendRecord {

    // MARK: - Bar Mark Queries

    static func queryBySpendingTrendsBarMarks(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> GRDBDatabase.RecordSQLBuilder<TrendRecord> {
        .init(
            record: TrendRecord.self,
            sql: """
            -- SpendingTrendsBarMarks by budgetId
            SELECT date(strftime('%Y-%m-01', transactionEntry.date)) as year_month, categoryGroup.name as name, SUM(amount) * -1 as total, categoryGroup.id as id,
            budgetSummary.currencyCode FROM transactionEntry
            INNER JOIN account on account.id = transactionEntry.accountId
            INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
            INNER JOIN category on category.id = transactionEntry.categoryId
            INNER JOIN  categoryGroup on categoryGroup.id = category.categoryGroupId
            WHERE date BETWEEN :fromDate AND :toDate
            AND account.onBudget = 1
            AND transactionEntry.deleted <> 1
            """ +
            .andAccountIds(accountIds) +
            """
            AND transactionEntry.budgetSummaryId = :budgetId
            AND ((categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ) OR categoryGroup.name <> 'Internal Master Category')
            GROUP BY year_month, categoryGroup.name
            HAVING total <> 0
            ORDER BY year_month ASC, total asc
            """,
            arguments: [
                "fromDate": Date.iso8601local.string(from: fromDate),
                "toDate": Date.iso8601local.string(from: toDate),
                "budgetId": budgetId,
            ]
        )
    }

    static func queryBySpendingTrendsBarMarks(
        categoryGroupId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> GRDBDatabase.RecordSQLBuilder<TrendRecord> {
        .init(
            record: TrendRecord.self,
            sql: """
            -- SpendingTrendsBarMarks by categoryGroupId
            SELECT date(strftime('%Y-%m-01', transactionEntry.date)) as year_month, category.name as name, SUM(amount) * -1 as total, categoryGroup.id as id,
            budgetSummary.currencyCode FROM transactionEntry
            INNER JOIN account on account.id = transactionEntry.accountId
            INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
            INNER JOIN category on category.id = transactionEntry.categoryId
            INNER JOIN  categoryGroup on categoryGroup.id = category.categoryGroupId
            WHERE date BETWEEN :fromDate AND :toDate
            AND account.onBudget = 1
            AND transactionEntry.deleted <> 1
            """ +
            .andAccountIds(accountIds) +
            """
            AND categoryGroup.id = :categoryGroupId
            AND ((categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ) OR categoryGroup.name <> 'Internal Master Category')
            GROUP BY year_month, category.name
            HAVING total <> 0
            ORDER BY year_month ASC, total asc
            """,
            arguments: [
                "fromDate": Date.iso8601local.string(from: fromDate),
                "toDate": Date.iso8601local.string(from: toDate),
                "categoryGroupId": categoryGroupId,
            ]
        )
    }

    // MARK: - Line Marks Queries

    static func queryBySpendingTrendsLineMarks(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> GRDBDatabase.RecordSQLBuilder<TrendRecord> {
        .init(
            record: TrendRecord.self,
            sql: """
            -- SpendingTrendsLineMarks by budgetId
            SELECT date(strftime('%Y-%m-01', transactionEntry.date)) as year_month, SUM(amount) * -1 as total, budgetSummary.currencyCode FROM transactionEntry
            INNER JOIN account on account.id = transactionEntry.accountId
            INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
            INNER JOIN category on category.id = transactionEntry.categoryId
            INNER JOIN  categoryGroup on categoryGroup.id = category.categoryGroupId
            WHERE date BETWEEN :fromDate AND :toDate
            AND account.onBudget = 1
            AND transactionEntry.deleted <> 1
            """ +
            .andAccountIds(accountIds) +
            """
            AND transactionEntry.budgetSummaryId = :budgetId
            AND ((categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ) OR categoryGroup.name <> 'Internal Master Category')
            GROUP BY year_month
            HAVING total <> 0
            ORDER BY year_month ASC, total asc
            """,
            arguments: [
                "fromDate": Date.iso8601local.string(from: fromDate),
                "toDate": Date.iso8601local.string(from: toDate),
                "budgetId": budgetId,
            ]
        )
    }

    static func queryBySpendingTrendsLineMarks(
        categoryGroupId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> GRDBDatabase.RecordSQLBuilder<TrendRecord> {
        .init(
            record: TrendRecord.self,
            sql: """
            -- SpendingTrendsLineMarks by categoryGroupId
            SELECT date(strftime('%Y-%m-01', transactionEntry.date)) as year_month, SUM(amount) * -1 as total, budgetSummary.currencyCode FROM transactionEntry
            INNER JOIN account on account.id = transactionEntry.accountId
            INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
            INNER JOIN category on category.id = transactionEntry.categoryId
            INNER JOIN  categoryGroup on categoryGroup.id = category.categoryGroupId
            WHERE date BETWEEN :fromDate AND :toDate
            AND account.onBudget = 1
            AND transactionEntry.deleted <> 1
            """ +
            .andAccountIds(accountIds) +
            """
            AND categoryGroup.id = :categoryGroupId
            AND ((categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ) OR categoryGroup.name <> 'Internal Master Category')
            GROUP BY year_month
            HAVING total <> 0
            ORDER BY year_month ASC, total asc
            """,
            arguments: [
                "fromDate": Date.iso8601local.string(from: fromDate),
                "toDate": Date.iso8601local.string(from: toDate),
                "categoryGroupId": categoryGroupId,
            ]
        )
    }

}

// swiftlint:enable line_length
