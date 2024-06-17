// Created by Daniel Amoafo on 18/5/2024.

import BudgetSystemService
import Foundation
import GRDB
import MoneyCommon

/// Store last known server knowledge values.
/// This improves fetch requests & speeds data transfer from YNAB server endpoints
/// by only getting changed values since the last fetch
/// see: https://api.ynab.com/#deltas
struct ServerKnowledgeConfig: Codable, FetchableRecord, PersistableRecord, CustomDebugStringConvertible, Sendable {

    nonisolated(unsafe) static let budgetSummary = belongsTo(BudgetSummary.self)

    let budgetId: String

    // Last Known Server Knowledges
    var categories: Int?
    var transactions: Int?

    var debugDescription: String {
        "budgetId: \(budgetId), categories(\(String(describing: categories)), " +
        "transactions(\(String(describing: transactions)))"
    }

    typealias Column = CodingKeys

    enum CodingKeys: String, CodingKey, ColumnExpression {
        case budgetId = "budgetSummaryId"
        case categories
        case transactions
    }

    enum Value: Sendable {
        case categories(Int), transactions(Int)
    }
}

// MARK: - BudgetService

extension BudgetSummary: @retroactive MutablePersistableRecord {}
extension BudgetSummary: @retroactive TableRecord {}
extension BudgetSummary: @retroactive EncodableRecord {}
extension BudgetSummary: @retroactive PersistableRecord {}
extension BudgetSummary: @retroactive FetchableRecord {

    nonisolated(unsafe) static let transactions = hasMany(TransactionEntry.self)
    nonisolated(unsafe) static let dbAccounts = hasMany(Account.self)
    nonisolated(unsafe) static let categoryGroup = hasMany(CategoryGroup.self)

    public func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["name"] = name
        container["lastModifiedOn"] = lastModifiedOn
        container["firstMonth"] = firstMonth
        container["lastMonth"] = lastMonth
        container["currencyCode"] = currencyCode
    }

    enum Column: String, CodingKey, ColumnExpression {
        case id, name, lastModifiedOn, firstMonth, lastMonth, currencyCode
    }

    public init(row: Row) throws {
        self.init(
            id: row[Column.id.rawValue],
            name: row[Column.name.rawValue],
            lastModifiedOn: row[Column.lastModifiedOn],
            firstMonth: row[Column.firstMonth],
            lastMonth: row[Column.lastMonth],
            currencyCode: row[Column.currencyCode]
        )
    }
}

extension Account: @retroactive MutablePersistableRecord {}
extension Account: @retroactive TableRecord {}
extension Account: @retroactive EncodableRecord {}
extension Account: @retroactive PersistableRecord {}
extension Account: @retroactive FetchableRecord {

    nonisolated(unsafe) static let budgetSummary = belongsTo(BudgetSummary.self)

    enum Column: String, CodingKey, ColumnExpression {
        case id, name, onBudget, closed, deleted
        case budgetId = "budgetSummaryId"
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Column.id.rawValue] = id
        container[Column.budgetId.rawValue] = budgetId
        container[Column.name.rawValue] = name
        container[Column.onBudget.rawValue] = onBudget
        container[Column.closed.rawValue] = closed
        container[Column.deleted.rawValue] = deleted
    }

    public init(row: Row) throws {
        self.init(
            id: row[Column.id.rawValue],
            budgetId: row[Column.budgetId.rawValue],
            name: row[Column.name.rawValue],
            onBudget: row[Column.onBudget.rawValue],
            closed: row[Column.closed.rawValue],
            deleted: row[Column.deleted.rawValue]
        )
    }
}

extension CategoryGroup: @retroactive MutablePersistableRecord {}
extension CategoryGroup: @retroactive TableRecord {}
extension CategoryGroup: @retroactive EncodableRecord {}
extension CategoryGroup: @retroactive PersistableRecord {}
extension CategoryGroup: @retroactive FetchableRecord {

    nonisolated(unsafe) static let budgetSummary = belongsTo(BudgetSummary.self)
    nonisolated(unsafe) static let category = hasMany(Category.self)

    enum Column: String, CodingKey, ColumnExpression {
        case id, name, hidden, deleted
        case budgetId = "budgetSummaryId"
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Column.id.rawValue] = id
        container[Column.name.rawValue] = name
        container[Column.hidden.rawValue] = hidden
        container[Column.deleted.rawValue] = deleted
        container[Column.budgetId.rawValue] = budgetId
    }

    public init(row: Row) throws {
        self.init(
            id: row[Column.id.rawValue],
            name: row[Column.name.rawValue],
            hidden: row[Column.hidden.rawValue],
            deleted: row[Column.deleted.rawValue] as Bool? ?? false,
            budgetId: row[Column.budgetId.rawValue]
        )
    }
}

typealias Category = BudgetSystemService.Category

extension Category: @retroactive MutablePersistableRecord {}
extension Category: @retroactive TableRecord {}
extension Category: @retroactive EncodableRecord {}
extension Category: @retroactive PersistableRecord {}
extension Category: @retroactive FetchableRecord {

    nonisolated(unsafe) static let budgetSummary = belongsTo(BudgetSummary.self)
    nonisolated(unsafe) static let categoryGroup = belongsTo(CategoryGroup.self)

    enum Column: String, CodingKey, ColumnExpression {
        case id, name, hidden, deleted, categoryGroupId
        case budgetId = "budgetSummaryId"
    }

    public func encode(to container: inout GRDB.PersistenceContainer) throws {
        container[Column.id.rawValue] = id
        container[Column.name.rawValue] = name
        container[Column.hidden.rawValue] = hidden
        container[Column.deleted.rawValue] = deleted
        container[Column.categoryGroupId.rawValue] = categoryGroupId
        container[Column.budgetId.rawValue] = budgetId
    }

    public init(row: Row) throws {
        self.init(
            id: row[Column.id.rawValue],
            categoryGroupId: row[Column.categoryGroupId.rawValue],
            name: row[Column.name.rawValue],
            hidden: row[Column.hidden.rawValue],
            deleted: row[Column.deleted.rawValue] as Bool? ?? false,
            budgetId: row[Column.budgetId.rawValue]
        )
    }
}

extension TransactionEntry: @retroactive MutablePersistableRecord {}
extension TransactionEntry: @retroactive TableRecord {}
extension TransactionEntry: @retroactive EncodableRecord {}
extension TransactionEntry: @retroactive PersistableRecord {}
extension TransactionEntry: @retroactive FetchableRecord {

    nonisolated(unsafe) static let budgetSummary = belongsTo(BudgetSummary.self)

    var budgetSummary: QueryInterfaceRequest<BudgetSummary> {
        request(for: TransactionEntry.budgetSummary)
     }

    enum Column: String, CodingKey, ColumnExpression {
        case id, date, payeeName, accountId, accountName, categoryId, categoryName
        case categoryGroupId, transferAccountId, deleted, currencyCode
        case budgetId = "budgetSummaryId"
        case rawAmount = "amount"
    }

    public func encode(to container: inout GRDB.PersistenceContainer) throws {
        container[Column.id.rawValue] = id
        container[Column.date.rawValue] = date
        container[Column.budgetId.rawValue] = budgetId
        container[Column.rawAmount.rawValue] = rawAmount
        container[Column.currencyCode.rawValue] = currency.code
        container[Column.payeeName.rawValue] = payeeName
        container[Column.accountId.rawValue] = accountId
        container[Column.accountName.rawValue] = accountName
        container[Column.categoryId.rawValue] = categoryId
        container[Column.categoryName.rawValue] = categoryName
        container[Column.transferAccountId.rawValue] = transferAccountId
        container[Column.deleted.rawValue] = deleted
    }

    public init(row: Row) {
        self.init(
            id: row[Column.id.rawValue],
            budgetId: row[Column.budgetId.rawValue],
            date: row[Column.date.rawValue],
            rawAmount: row[Column.rawAmount.rawValue],
            currencyCode: row[Column.currencyCode.rawValue],
            payeeName: row[Column.payeeName.rawValue],
            accountId: row[Column.accountId.rawValue],
            accountName: row[Column.accountName.rawValue],
            categoryId: row[Column.categoryId.rawValue],
            categoryName: row[Column.categoryName.rawValue],
            transferAccountId: row[Column.transferAccountId.rawValue],
            deleted: row[Column.deleted.rawValue] as Bool? ?? false
        )
    }

}

// MARK: - Database Records

/// Represents a `Category` or `CategoryGroup` entry with the aggregated total amounts for transactions belonging to the type
/// Used to make plottable chart graph data
struct CategoryRecord: Identifiable, Equatable, Codable, FetchableRecord, Sendable {

    private let _id: String
    let name: String
    let total: Money

    var id: String { _id }

    init(id: String, name: String, total: Money) {
        self._id = id
        self.name = name
        self.total = total
    }

    init(row: Row) throws {
        let currencyCode = row["currencyCode"] as String? ?? ""
        guard let currency = Currency.iso4217Currency(for: currencyCode) else {
            fatalError("unable to parse currencyCode: [\(currencyCode)]")
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

struct TrendRecord: Identifiable, Equatable, Codable, FetchableRecord {

    let id: String
    let date: Date
    let name: String
    let total: Money

    enum Column: String, CodingKey, ColumnExpression {
        case name, total
        case date = "year_month"
        case recordId = "id"
    }

    init(date: Date, name: String, total: Money, recordId: String) {
        self.date = date
        self.name = name
        self.total = total
        let dateString = Date.iso8601local.string(from: date)
        self.id = "\(dateString)-\(recordId)"
    }

    init(row: Row) throws {
        let currencyCode = row["currencyCode"] as String? ?? ""
        guard let currency = Currency.iso4217Currency(for: currencyCode) else {
            fatalError("unable to parse currencyCode: [\(currencyCode)]")
        }
        guard let total = row["total"] as Int? else {
            fatalError("unable to parse total field into Int value")
        }

        let id = if row.hasColumn(Column.recordId.rawValue) {
            row[Column.recordId.rawValue] as String
        } else {
            ""
        }

        let name = if row.hasColumn(Column.name.rawValue) {
            row[Column.name.rawValue] as String
        } else {
            ""
        }

        self.init(
            date: row[Column.date.rawValue],
            name: name,
            total: Money.forYNAB(amount: total, currency: currency),
            recordId: id
        )
    }
}
