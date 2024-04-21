//  Created by Daniel Amoafo on 3/2/2024.
//

import Foundation
import MoneyCommon

public struct Account: Identifiable, Equatable, CustomStringConvertible {

    public var id: String
    public var name: String

    public var description: String { name }

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct BudgetSummary: Identifiable, Equatable, CustomStringConvertible {
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
}


public struct Transaction: Identifiable, Equatable, CustomStringConvertible {

    public let id: String

    public let date: Date

    public let money: Money

    /// Id of the account this transaction belongs to
    public let accountId: String

    /// Name of the account this transaction belongs to
    public let accountName: String

    /// Category id
    public let categoryId: String?

    /// Category name
    public let categoryName: String?

    public var description: String { 
        "\(id), \(dateFormated()), \(categoryName ?? ""),\(amountFormatted())"
    }

    public func dateFormated() -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    public func amountFormatted(formatter suppliedFormatter: NumberFormatter? = nil) -> String {

        let formatter: NumberFormatter
        let currency = money.currency
        if let suppliedFormatter {
            precondition(suppliedFormatter.currencyCode == currency.code)
            formatter = suppliedFormatter
        } else {
            formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency.code
            formatter.minimumFractionDigits = currency.minorUnit
            formatter.maximumFractionDigits = currency.minorUnit
        }
        return formatter.string(for: money.amount) ?? ""
    }
}
