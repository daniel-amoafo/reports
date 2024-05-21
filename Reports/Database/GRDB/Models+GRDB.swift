// Created by Daniel Amoafo on 18/5/2024.

import BudgetSystemService
import Foundation
import GRDB
import MoneyCommon

/// Store last known server knowledge values.
/// This improves fetch requests & speeds data transfer from YNAB server endpoints
/// by only getting changed values since the last fetch
/// see: https://api.ynab.com/#deltas
struct ServerKnowledgeConfig: Codable, FetchableRecord, PersistableRecord {

    static let budgetSummary = belongsTo(BudgetSummary.self)

    let budgetId: String
    // Last Known Server Knowledges
    var categories: Int?
    var transactions: Int?

    enum CodingKeys: String, CodingKey {
        case budgetId = "budgetSummaryId"
        case categories
        case transactions
    }

}

// MARK: - BudgetService

extension BudgetSummary: FetchableRecord, PersistableRecord {

    static let transactions = hasMany(TransactionEntry.self)
    static let dbAccounts = hasMany(Account.self)

    public func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["name"] = name
        container["lastModifiedOn"] = lastModifiedOn
        container["firstMonth"] = firstMonth
        container["lastMonth"] = lastMonth
        container["currencyCode"] = currencyCode
    }

}

extension Account: FetchableRecord, PersistableRecord {

    static let budgetSummary = belongsTo(BudgetSummary.self)

    public func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["name"] = name
        container["budgetSummaryId"] = budgetId
        container["onBudget"] = onBudget
        container["deleted"] = deleted
    }

}

extension TransactionEntry: FetchableRecord, PersistableRecord {

    static let budgetSummary = belongsTo(BudgetSummary.self)

    var budgetSummary: QueryInterfaceRequest<BudgetSummary> {
        request(for: TransactionEntry.budgetSummary)
     }

    enum DBCodingKey: String, CodingKey {
        case id, date, payeeName, accountId, accountName, categoryId, categoryName
        case categoryGroupId, categoryGroupName, transferAccountId, deleted, currencyCode
        case budgetId = "budgetSummaryId"
        case rawAmount = "amount"
    }

    public func encode(to container: inout GRDB.PersistenceContainer) throws {
        container[DBCodingKey.id.rawValue] = id
        container[DBCodingKey.date.rawValue] = date
        container[DBCodingKey.budgetId.rawValue] = budgetId
        container[DBCodingKey.rawAmount.rawValue] = rawAmount
        container[DBCodingKey.currencyCode.rawValue] = currency.code
        container[DBCodingKey.payeeName.rawValue] = payeeName
        container[DBCodingKey.accountId.rawValue] = accountId
        container[DBCodingKey.accountName.rawValue] = accountName
        container[DBCodingKey.categoryId.rawValue] = categoryId
        container[DBCodingKey.categoryName.rawValue] = categoryName
        container[DBCodingKey.categoryGroupId.rawValue] = categoryGroupId
        container[DBCodingKey.categoryGroupName.rawValue] = categoryGroupName
        container[DBCodingKey.transferAccountId.rawValue] = transferAccountId
        container[DBCodingKey.transferAccountId.rawValue] = deleted
    }

    public init(row: Row) {
        self.init(
            id: row[DBCodingKey.id.rawValue],
            budgetId: row[DBCodingKey.budgetId.rawValue],
            date: row[DBCodingKey.date.rawValue],
            rawAmount: row[DBCodingKey.rawAmount.rawValue],
            currencyCode: row[DBCodingKey.currencyCode.rawValue],
            payeeName: row[DBCodingKey.payeeName.rawValue],
            accountId: row[DBCodingKey.accountId.rawValue],
            accountName: row[DBCodingKey.accountName.rawValue],
            categoryId: row[DBCodingKey.categoryId.rawValue],
            categoryName: row[DBCodingKey.categoryName.rawValue],
            categoryGroupId: row[DBCodingKey.categoryGroupId.rawValue],
            categoryGroupName: row[DBCodingKey.categoryGroupName.rawValue],
            transferAccountId: row[DBCodingKey.transferAccountId.rawValue],
            deleted: row[DBCodingKey.deleted.rawValue]
        )
    }

}

// MARK: - Database Records

struct CategoryRecord: Identifiable, Codable, FetchableRecord {

    let id: String
    let name: String
    let total: Money

    init(id: String, name: String, total: Money) {
        self.id = id
        self.name = name
        self.total = total
    }

    init(row: Row) throws {
        let currencyCode = row["currencyCode"] as String? ?? ""
        guard let currency = Currency.iso4217Currency(for: currencyCode) else {
            fatalError("unable to parse currencyCode: \(currencyCode)")
        }
        guard let total = row["total"] as Int? else {
            fatalError("unable to parse total field into Int value")
        }
        self.init(
            id: row["id"],
            name: row["name"],
            total: Money.forYNAB(amount: total, currency: currency)
        )
    }

}
