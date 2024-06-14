// Created by Daniel Amoafo on 14/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

/// Manages calls to Database queries
enum CategoryListQueries {

    static let logger = LogFactory.create(Self.self)

    static var grdb: GRDBDatabase {
        @Dependency(\.database.grdb) var grdb
        return grdb
    }

    static func fetchCategoryGroupTotals(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> [CategoryRecord] {
        do {
            let categoryGroupBuilder = CategoryRecord
                .queryTransactionsByCategoryGroupTotals(
                    budgetId: budgetId,
                    startDate: fromDate,
                    finishDate: toDate,
                    accountIds: accountIds
                )

            return try grdb.fetchRecords(builder: categoryGroupBuilder)
        } catch {
            logger.error("\(String(describing: error))")
            return []
        }
    }

    static func fetchCategoryTotals(
        categoryGroupId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?
    ) -> ([CategoryRecord], String) {
        do {
            let categoryBuilder = CategoryRecord
                .queryTransactionsByCategoryTotals(
                    forCategoryGroupId: categoryGroupId,
                    startDate: fromDate,
                    finishDate: toDate,
                    accountIds: accountIds
                )
            let records = try Self.grdb.fetchRecords(builder: categoryBuilder)

            let groupName = try CategoryGroup.fetch(id: categoryGroupId)?.name ?? ""

            return (records, groupName)
        } catch {
            Self.logger.error("\(error.toString())")
            return ([], "")
        }
    }

    static func fetchTransactionEntries(for categoryId: String, fromDate: Date, toDate: Date, accountIds: String?)
    -> IdentifiedArrayOf<TransactionEntry> {
        do {
            let transactionsBuilder = TransactionEntry.queryTransactionsByCategoryId(
                categoryId,
                startDate: fromDate,
                finishDate: toDate,
                accountIds: accountIds
            )
            let transactions = try Self.grdb.fetchRecords(builder: transactionsBuilder)

            return .init(uniqueElements: transactions)
        } catch {
            Self.logger.error("\(error.toString())")
            return .init(uniqueElements: [])
        }
    }
}
