//  Created by Daniel Amoafo on 3/2/2024.
//

import Foundation
import MoneyCommon

//@DebugDescription
public struct BudgetSummary: Identifiable, Equatable, Codable, Sendable, CustomStringConvertible {
    /// Budget id
    public let id: String

    /// Budget name
    public let name: String

    /// Date the budget was last modified
    public let lastModifiedOn: String

    /// Budget's first month
    public let firstMonth: String

    /// Budget's last month
    public let lastMonth: String

    public let currency: Currency

    public let accounts: [Account]

    public init(
        id: String,
        name: String,
        lastModifiedOn: String,
        firstMonth: String,
        lastMonth: String,
        currency: Currency,
        accounts: [Account]
    ) {
        self.id = id
        self.name = name
        self.lastModifiedOn = lastModifiedOn
        self.firstMonth = firstMonth
        self.lastMonth = lastMonth
        self.currency = currency
        self.accounts = accounts
    }

    public init(
        id: String,
        name: String,
        lastModifiedOn: String,
        firstMonth: String,
        lastMonth: String,
        currencyCode: String
    ) {
        guard let currency = Currency.iso4217Currency(for: currencyCode) else {
            fatalError("Unable to parse currencyCode (\(currencyCode)) in a known Currency")
        }
        self.init(
            id: id,
            name: name,
            lastModifiedOn: lastModifiedOn,
            firstMonth: firstMonth,
            lastMonth: lastMonth,
            currency: currency,
            accounts: []
        )
    }

    public var currencyCode: String { currency.code }

    public var description: String { name }

    public var debugDescription: String {
        "id: \(id), name: \(name), lastModifiedOn: \(lastModifiedOn), currency: \(currency)"
    }
}

//@DebugDescription
public struct Account: Identifiable, Equatable, Codable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {

    public var id: String
    public var budgetId: String
    public var name: String
    public var onBudget: Bool
    public var closed: Bool
    public var deleted: Bool

    public init(id: String, budgetId: String, name: String, onBudget: Bool, closed: Bool, deleted: Bool) {
        self.id = id
        self.budgetId = budgetId
        self.name = name
        self.onBudget = onBudget
        self.closed = closed
        self.deleted = deleted
    }

    public var description: String { name }

    public var debugDescription: String {
        "name: \(name), onBudget: \(onBudget), closed: \(closed), deleted: \(deleted), id: \(id), budgetId: \(budgetId)"
    }
}

//@DebugDescription
public struct CategoryGroup: Identifiable, Equatable, Codable, Sendable, CustomStringConvertible {
    /// Category group id
    public let id: String

    /// Category  Group name
    public let name: String

    /// Whether or not the category is hidden
    public let hidden: Bool

    /// Whether or not the category is deleted
    public let deleted: Bool

    public let budgetId: String

    public init(
        id: String,
        name: String,
        hidden: Bool,
        deleted: Bool,
        budgetId: String
    ) {
        self.id = id
        self.name = name
        self.hidden = hidden
        self.deleted = deleted
        self.budgetId = budgetId
    }

    public var description: String { name }

    public var debugDescription: String {
        "id: \(id), name: \(name), hidden: \(hidden), deleted: \(deleted), budgetId: \(budgetId)"
    }
}

//@DebugDescription
public struct Category: Identifiable, Equatable, Codable, Sendable, CustomStringConvertible {
    /// Category id
    public let id: String

    /// Category group id
    public let categoryGroupId: String

    /// Category name
    public let name: String

    /// Whether or not the category is hidden
    public let hidden: Bool

    /// Whether or not the category is deleted
    public let deleted: Bool

    public let budgetId: String

    public init(id: String, categoryGroupId: String, name: String, hidden: Bool, deleted: Bool, budgetId: String) {
        self.id = id
        self.categoryGroupId = categoryGroupId
        self.name = name
        self.hidden = hidden
        self.deleted = deleted
        self.budgetId = budgetId
    }

    public var description: String { name }

    public var debugDescription: String {
        "id: \(id), name: \(name), deleted: \(deleted), categoryGroupId: \(categoryGroupId)"
    }
}

//@DebugDescription
public struct TransactionEntry: Identifiable, Equatable, Codable, Sendable, CustomStringConvertible {

    public let id: String

    public let budgetId: String

    public let date: Date

    public let rawAmount: Int

    public let currency: Currency

    public let payeeName: String?

    /// Id of the account this transaction belongs to
    public let accountId: String

    /// Name of the account this transaction belongs to
    public let accountName: String

    /// Category id
    public let categoryId: String?

    /// Category name
    public let categoryName: String?

    public let transferAccountId: String?

    public let deleted: Bool

    public init(
        id: String,
        budgetId: String,
        date: Date,
        rawAmount: Int,
        currencyCode: String,
        payeeName: String?,
        accountId: String,
        accountName: String,
        categoryId: String?,
        categoryName: String?,
        transferAccountId: String?,
        deleted: Bool
    ) {
        self.id = id
        self.budgetId = budgetId
        self.date = date
        self.rawAmount = rawAmount
        self.payeeName = payeeName
        self.accountId = accountId
        self.accountName = accountName
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.transferAccountId = transferAccountId
        self.deleted = deleted

        guard let currency = Currency.iso4217Currency(for: currencyCode) else {
            fatalError("unable to parse currencyCode to a Currency value")
        }
        self.currency = currency
    }

    public var dateFormated: String {
        Date.iso8601local.string(from: date)
    }

    public var dateFormatedLong: String {
        date.formatted(date: .long, time: .omitted)
    }

    public var amountFormatted: String {
        return  money.amountFormatted
    }

    public var money: Money {
        Money.forYNAB(amount: rawAmount, currency: currency)
    }

    public var description: String {
        "\(id), \(dateFormated), \(amountFormatted)"
    }

    public var debugDescription: String {
        "id: \(id), rawAmount: \(rawAmount), payeeName: \(String(describing: payeeName)), date: \(date)"
    }
}
