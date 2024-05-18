//  Created by Daniel Amoafo on 3/2/2024.
//

import Foundation
import MoneyCommon

public struct Account: Identifiable, Equatable, CustomStringConvertible {

    public var id: String
    public var name: String
    public var onBudget: Bool
    public var deleted: Bool
    public var description: String { name }

    public init(id: String, name: String, onBudget: Bool, deleted: Bool) {
        self.id = id
        self.name = name
        self.onBudget = onBudget
        self.deleted = deleted
    }
}

public struct BudgetSummary: Identifiable, Equatable, Codable, CustomStringConvertible {
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

    public var description: String { name }

    public var currencyCode: String { currency.code }

    public init(
        id: String,
        name: String,
        lastModifiedOn: String,
        firstMonth: String,
        lastMonth: String,
        currency: Currency
    ) {
        self.id = id
        self.name = name
        self.lastModifiedOn = lastModifiedOn
        self.firstMonth = firstMonth
        self.lastMonth = lastMonth
        self.currency = currency
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
            currency: currency
        )
    }

}

public struct CategoryGroup: Identifiable, Equatable, CustomStringConvertible {
    /// Category group id
    public let id: String

    /// Category name
    public let name: String

    /// Whether or not the category is hidden
    public let hidden: Bool

    /// Whether or not the category is deleted
    public let deleted: Bool

    public var description: String { name }

    public var categoryIds: [String]

    public init(id: String, name: String, hidden: Bool, deleted: Bool, categoryIds: [String]) {
        self.id = id
        self.name = name
        self.hidden = hidden
        self.deleted = deleted
        self.categoryIds = categoryIds
    }
}

public struct Category: Identifiable, Equatable, CustomStringConvertible {
    /// Category id
    public let id: String

    /// Category group id
    public let categoryGroupId: String

    /// Category name
    public let name: String

    /// Whether or not the category is hidden
    public let hidden: Bool

    /// Category note
    public let note: String?

    /// Current balance on this category
    public let balance: Money

    /// Whether or not the category is deleted
    public let deleted: Bool

    public var description: String { name }

    public init(id: String, categoryGroupId: String, name: String, hidden: Bool, note: String?, balance: Money, deleted: Bool) {
        self.id = id
        self.categoryGroupId = categoryGroupId
        self.name = name
        self.hidden = hidden
        self.note = note
        self.balance = balance
        self.deleted = deleted
    }
}


public struct TransactionEntry: Identifiable, Equatable, Codable, CustomStringConvertible {

    public let id: String

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

    public let categoryGroupId: String?

    public let categoryGroupName: String?

    /// Category name
    public let categoryName: String?

    public let transferAccountId: String?

    public let deleted: Bool

    public var description: String { 
        "\(id), \(dateFormated), \(categoryName ?? ""), \(amountFormatted)"
    }

    public var money: Money {
        Money.forYNAB(amount: rawAmount, currency: currency)
    }

    public init(
        id: String,
        date: Date,
        rawAmount: Int,
        currencyCode: String,
        payeeName: String?,
        accountId: String,
        accountName: String,
        categoryId: String?,
        categoryName: String?,
        categoryGroupId: String?,
        categoryGroupName: String?,
        transferAccountId: String?,
        deleted: Bool
    ) {
        self.id = id
        self.date = date
        self.rawAmount = rawAmount
        self.payeeName = payeeName
        self.accountId = accountId
        self.accountName = accountName
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryGroupId = categoryGroupId
        self.categoryGroupName = categoryGroupName
        self.transferAccountId = transferAccountId
        self.deleted = deleted

        guard let currency = Currency.iso4217Currency(for: currencyCode) else {
            fatalError("unable to parse currencyCode to a Currency value")
        }
        self.currency = currency
    }

    public var dateFormated: String {
        Date.iso8601Formatter.string(from: date)
    }

    public var dateFormatedLong: String {
        date.formatted(date: .long, time: .omitted)
    }

    public var amountFormatted: String {
        return  money.amountFormatted
    }
}
