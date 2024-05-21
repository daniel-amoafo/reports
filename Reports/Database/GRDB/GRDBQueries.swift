// Created by Daniel Amoafo on 21/5/2024.

import Foundation


extension CategoryRecord {

    // MARK: CategoryRecord Queries

    /// Creates CategoryGroup total amounts  for a given date range.
    /// The record entry values can be used directly to plot data in a chart.
    static func queryTransactionsByCategoryGroupTotals(startDate: Date, finishDate: Date)
    -> GRDBDatabase.RecordSQLBuilder<CategoryRecord> {
        .init(
            record: CategoryRecord.self,
            sql: """
                SELECT categoryName as name, SUM(amount) as total, categoryGroupId as id, budgetSummary.currencyCode FROM transactionEntry
                INNER JOIN account on account.id = transactionEntry.accountId
                INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
                WHERE date BETWEEN ? AND ?
                AND account.onBudget = 1
                GROUP BY categoryGroupName
                HAVING total <> 0
                ORDER BY total ASC
            """,
            arguments: [
                Date.iso8601local.string(from: startDate),
                Date.iso8601local.string(from: finishDate),
            ]
        )
    }
}
