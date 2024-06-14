// Created by Daniel Amoafo on 14/6/2024.

import Foundation

extension CategoryRecord {

    /// Creates `CategoryGroup` total amounts  for a given date range.
    /// The record entry values can be used directly to plot data in a chart.
    static func queryTransactionsByCategoryGroupTotals(budgetId: String, startDate: Date, finishDate: Date, accountIds: String?)
    -> GRDBDatabase.RecordSQLBuilder<CategoryRecord> {
        .init(
            record: CategoryRecord.self,
            sql: """
            SELECT categoryGroup.name as name, SUM(amount) as total, categoryGroup.id as id,
            budgetSummary.currencyCode FROM transactionEntry
            INNER JOIN account on account.id = transactionEntry.accountId
            INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
            INNER JOIN category on category.id = transactionEntry.categoryId
            INNER JOIN  categoryGroup on categoryGroup.id = category.categoryGroupId
            WHERE date BETWEEN :startDate AND :finishDate
            AND account.onBudget = 1
            AND transactionEntry.deleted <> 1
            """ +
            .andAccountIds(accountIds) +
            """
            AND transactionEntry.budgetSummaryId = :budgetId
            AND ( (categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ) OR categoryGroup.name <> 'Internal Master Category')
            GROUP BY categoryGroup.name
            HAVING total <> 0
            ORDER BY total ASC
            """,
            arguments: [
                "startDate": Date.iso8601local.string(from: startDate),
                "finishDate": Date.iso8601local.string(from: finishDate),
                "budgetId": budgetId,
            ]
        )
    }

    /// Creates `Category` total amounts  for a given date range.
    /// The record entry values can be used directly to plot data in a chart.
    static func queryTransactionsByCategoryTotals(
        forCategoryGroupId categoryGroupId: String,
        startDate: Date,
        finishDate: Date,
        accountIds: String?
    )
    -> GRDBDatabase.RecordSQLBuilder<CategoryRecord> {
        .init(
            record: CategoryRecord.self,
            sql: """
            SELECT category.name as name, SUM(amount) as total, category.id as id,
            budgetSummary.currencyCode FROM transactionEntry
            INNER JOIN account on account.id = transactionEntry.accountId
            INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
            INNER JOIN category on category.id = transactionEntry.categoryId
            INNER JOIN  categoryGroup on categoryGroup.id = category.categoryGroupId
            WHERE date BETWEEN :startDate AND :finishDate
            AND account.onBudget = 1
            AND transactionEntry.deleted <> 1
            """ +
            .andAccountIds(accountIds) +
            """
            AND categoryGroup.id = :categoryGroupId
            AND ( categoryGroup.name <> 'Internal Master Category' OR (categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ))
            GROUP BY category.name
            HAVING total <> 0
            ORDER BY total ASC
            """,
            arguments: [
                "startDate": Date.iso8601local.string(from: startDate),
                "finishDate": Date.iso8601local.string(from: finishDate),
                "categoryGroupId": categoryGroupId,
            ]
        )
    }

}
