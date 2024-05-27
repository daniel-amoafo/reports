// Created by Daniel Amoafo on 21/5/2024.

import BudgetSystemService
import Dependencies
import Foundation

// Helper fixture to access the grdb instance
private enum Shared {

    @Dependency(\.database.grdb) static var grdb
}

extension Account {

    static func fetch(id: String) throws -> Self? {
        let request = Account.filter(id: id)
        return try Shared.grdb.fetchRecord(Self.self, request: request)
    }

}

extension CategoryGroup {

    static func fetch(id: String) throws -> Self? {
        let request = CategoryGroup.filter(id: id)
        return try Shared.grdb.fetchRecord(Self.self, request: request)
    }
}

// swiftlint:disable line_length
extension CategoryRecord {

    // MARK: CategoryRecord Queries

    /// Creates `CategoryGroup` total amounts  for a given date range.
    /// The record entry values can be used directly to plot data in a chart.
    static func queryTransactionsByCategoryGroupTotals(budgetId: String, startDate: Date, finishDate: Date)
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
            WHERE date BETWEEN ? AND ?
            AND account.onBudget = 1
            AND transactionEntry.budgetSummaryId = ?
            AND ( categoryGroup.name <> 'Internal Master Category' OR (categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ))
            GROUP BY categoryGroup.name
            HAVING total <> 0
            ORDER BY total ASC
            """,
            arguments: [
                Date.iso8601local.string(from: startDate),
                Date.iso8601local.string(from: finishDate),
                budgetId,
            ]
        )
    }

    /// Creates `Category` total amounts  for a given date range.
    /// The record entry values can be used directly to plot data in a chart.
    static func queryTransactionsByCategoryTotals(
        forCategoryGroupId categoryGroupId: String,
        startDate: Date,
        finishDate: Date
    )
    -> GRDBDatabase.RecordSQLBuilder<CategoryRecord> {
        .init(
            record: CategoryRecord.self,
            sql: """
                SELECT categoryName as name, SUM(amount) as total, categoryId as id, budgetSummary.currencyCode FROM transactionEntry
                INNER JOIN account on account.id = transactionEntry.accountId
                INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
                WHERE date BETWEEN ? AND ?
                AND account.onBudget = 1
                AND transactionEntry.categoryGroupId = ?
                GROUP BY categoryName
                HAVING total <> 0
                ORDER BY total ASC
            """,
            arguments: [
                Date.iso8601local.string(from: startDate),
                Date.iso8601local.string(from: finishDate),
                categoryGroupId,
            ]
        )
    }
}

// swiftlint:enable line_length
