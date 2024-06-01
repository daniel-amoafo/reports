// Created by Daniel Amoafo on 21/5/2024.

import BudgetSystemService
import Dependencies
import Foundation

import GRDB

// swiftlint:disable line_length

// Helper fixture to access the grdb instance
private enum Shared {

    @Dependency(\.database.grdb) static var grdb
}

extension ServerKnowledgeConfig {

    static func fetch(budgetId: String) throws -> Self? {
        let request = try fetchRequest(budgetId)
        return try Shared.grdb.fetchRecord(Self.self, request: request)
    }

    private static func fetchRequest(_ budgetId: String) throws -> QueryInterfaceRequest<Self> {
        guard budgetId.isNotEmpty else {
            throw GRDBDatabase.ValidationError.missingBudgetId
        }

        let request = Self
            .filter(ServerKnowledgeConfig.Column.budgetId == budgetId)
        return request
    }

    /// Updates a ServerConfigKnowledge record with a new serverKnowledge value.
    /// If one does not exists for the provided budgetId, it'll be created.
    fileprivate static func update(value: Value, budgetId: String, db: GRDB.Database) throws {

        guard budgetId.isNotEmpty else {
            throw GRDBDatabase.ValidationError.missingBudgetId
        }

        var serverConfig = try fetchRequest(budgetId).fetchOne(db) ?? .init(budgetId: budgetId)

        switch value {

        case let .categories(serverKnowledge):
            serverConfig.categories = serverKnowledge
        case let .transactions(serverKnowledge):
            serverConfig.transactions = serverKnowledge
        }

        try serverConfig.upsert(db)

        let logger = LogFactory.create(Self.self)
        logger.debug("server knowledge entry updated - \(serverConfig.debugDescription)")
    }
}

extension BudgetSummary {

    static func save(_ summaries: [BudgetSummary]) throws {
        try Shared.grdb.perform { db in
            for summary in summaries {
                try summary.save(db)
                for account in summary.accounts {
                    try account.save(db)
                }
            }
        }
    }
}

extension Account {

    static func fetch(id: String) throws -> Self? {
        let request = Account.filter(id: id)
        return try Shared.grdb.fetchRecord(Self.self, request: request)
    }

    static func fetch(isOnBudget: Bool, isDeleted: Bool) throws -> [Self] {
        let request = Account
            .filter(Account.Column.onBudget == isOnBudget)
            .filter(Account.Column.deleted == isDeleted)

        return try Shared.grdb.fetchRecords(Self.self, request: request)
    }
}

extension CategoryGroup {

    static func fetch(id: String) throws -> Self? {
        let request = CategoryGroup.filter(id: id)
        return try Shared.grdb.fetchRecord(Self.self, request: request)
    }
}

extension TransactionEntry {

    static func save(_ transactions: [TransactionEntry], serverKnowledge: Int) throws {

        guard let budgetId = transactions.first?.budgetId else { return }

        try Shared.grdb.perform { db in

            for transaction in transactions {
                try transaction.save(db)
            }

            try ServerKnowledgeConfig.update(
                value: .transactions(serverKnowledge),
                budgetId: budgetId,
                db: db
            )
        }

    }

    // MARK: TransactionEntry Queries

    static func queryTransactionsByCategoryId(_ categoryId: String, startDate: Date, finishDate: Date, accountId: String?)
    -> GRDBDatabase.RecordSQLBuilder<TransactionEntry> {
        .init(
            record: TransactionEntry.self,
            sql: """
            SELECT * FROM transactionEntry
            INNER JOIN account on account.id = transactionEntry.accountId
            INNER JOIN budgetSummary on budgetSummary.id = transactionEntry.budgetSummaryId
            INNER JOIN category on category.id = transactionEntry.categoryId
            INNER JOIN  categoryGroup on categoryGroup.id = category.categoryGroupId
            WHERE date BETWEEN :startDate AND :finishDate
            AND account.onBudget = 1
            """ +
            SQLHelper.contionalAccountId(accountId) +
            """
            AND transactionEntry.categoryId = :categoryId
            AND ( categoryGroup.name <> 'Internal Master Category' OR (categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ))
            ORDER BY date DESC
            """,
            arguments: [
                "startDate": Date.iso8601local.string(from: startDate),
                "finishDate": Date.iso8601local.string(from: finishDate),
                "categoryId": categoryId,
                "accountId": accountId,
            ].compactMapValues { $0 }
        )
    }
}

extension CategoryRecord {

    static func save(
        groups: [CategoryGroup],
        categories: [BudgetSystemService.Category],
        serverKnowledge: Int
    ) throws {

        guard let budgetId = groups.first?.budgetId else { return }

        try Shared.grdb.perform { db in
            for group in groups {
                try group.save(db)
            }

            for category in categories {
                try category.save(db)
            }

            // update the server knowledge in db.
            // Future API fetches will do a delta when the last known server knowledget
            // is sent over as part of an API request,
            try ServerKnowledgeConfig.update(
                value: .categories(serverKnowledge),
                budgetId: budgetId,
                db: db
            )
        }
    }

    // MARK: CategoryRecord Queries

    /// Creates `CategoryGroup` total amounts  for a given date range.
    /// The record entry values can be used directly to plot data in a chart.
    static func queryTransactionsByCategoryGroupTotals(budgetId: String, startDate: Date, finishDate: Date, accountId: String?)
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
            """ +
            SQLHelper.contionalAccountId(accountId) +
            """
            AND transactionEntry.budgetSummaryId = :budgetId
            AND ( categoryGroup.name <> 'Internal Master Category' OR (categoryGroup.name = 'Internal Master Category' AND category.name = 'Uncategorized' ))
            GROUP BY categoryGroup.name
            HAVING total <> 0
            ORDER BY total ASC
            """,
            arguments: [
                "startDate": Date.iso8601local.string(from: startDate),
                "finishDate": Date.iso8601local.string(from: finishDate),
                "budgetId": budgetId,
                "accountId": accountId,
            ].compactMapValues { $0 }
        )
    }

    /// Creates `Category` total amounts  for a given date range.
    /// The record entry values can be used directly to plot data in a chart.
    static func queryTransactionsByCategoryTotals(
        forCategoryGroupId categoryGroupId: String,
        startDate: Date,
        finishDate: Date,
        accountId: String?
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
            """ +
            SQLHelper.contionalAccountId(accountId) +
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
                "accountId": accountId,
            ].compactMapValues { $0 }
        )
    }

}

// MARK: -

private enum SQLHelper {

    static func contionalAccountId(_ accountId: String?) -> String {
        guard accountId != nil else { return " " }
        return """

        AND account.id = :accountId

        """
    }
}

// swiftlint:enable line_length
