// This file is based on https://github.com/Flight-School/Money project
import Foundation

/// An amount of money in a given currency.
public struct Money: Equatable, Hashable, Sendable {

    /// The amount of money.
    public let centsAmount: Int
    public let currency: Currency

    public var amount: Decimal {
        let result = toMajorUnitAmount as Decimal
        assert(!result.isNaN)
        assert(result.isFinite)
        return result
    }

    public init(minorUnitAmount: Int, currency: Currency) {
        self.centsAmount = minorUnitAmount
        self.currency = currency
    }

    /// Throws an error if <dollarAmount> isn't representable as an exact dollars + cents amount.
    public init(majorUnitAmount: Decimal, currency: Currency) {
        let dollarAmount = majorUnitAmount as NSDecimalNumber
        guard Money.isValid(dollarAmount: dollarAmount) else {
            fatalError(Money.Error.invalidDollarAmount(dollarAmount).description)
        }

        let unroundedCentsAmount = currency.minorUnitAmount(fromMajorUnitAmount: dollarAmount)
        let roundedCentsAmount = unroundedCentsAmount.rounding(accordingToBehavior: NSDecimalNumberHandler.roundPlain)

        guard roundedCentsAmount.isEqual(to: unroundedCentsAmount) else {
            fatalError(Money.Error.unroundedAmount(currency, dollarAmount).description)
        }

        guard let centsInt = Int(exactly: roundedCentsAmount) else {
            fatalError(Money.Error.centsAmountIntOverflow.description)
        }

        self.init(minorUnitAmount: centsInt, currency: currency)
    }

    public init(majorUnitAmount: Int, currency: Currency) {
        self.init(
            minorUnitAmount: currency
                .minorUnitAmount(fromMajorUnitAmount: .init(integerLiteral: majorUnitAmount)).intValue,
            currency: currency
        )
    }
    /**
        A monetary amount rounded to
        the number of places of the minor currency unit.
     */
    public var rounded: Money {
        return Money(majorUnitAmount: amount.rounded(for: currency), currency: currency)
    }
}

// MARK: - Conversion

public extension Money {

    /// Converts to major unit amount e.g. cents to dollars, e.g. 100 -> 1.00 for USD.
    var toMajorUnitAmount: NSDecimalNumber {
        currency.majorUnitAmount(fromMinorUnitAmount: .init(integerLiteral: centsAmount))
    }

    /// Returns true if the amount (or currency itself) doesn't have cents, e.g. $25 and ¥3, but not $22.10.
    var isWholeDollarAmount: Bool {
        guard currency.minorUnit > 0 else {
            return true
        }

        return ((abs(self.centsAmount) % currency.centsPerDollar) == 0)
    }

}

// MARK: - Formatting

public extension Money {
    
    var amountFormatted: String {
        amountFormatted(formatter: .standard, for: .current)
    }

    var amountFormattedAbbreviated: String {
        amountFormatted(formatter: .abbreviated(signOption: .none), for: .current)
    }

    func amountFormatted(formatter: MoneyFormatter, for locale: Locale) -> String {
        formatter.stringValue(for: self, locale: locale)
    }
}

// MARK: - Comparable

extension Money: Comparable {
    public static func < (lhs: Money, rhs: Money) -> Bool {
        return lhs.amount < rhs.amount
    }
}

extension Money {
    /// The sum of two monetary amounts.
    public static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency)
        return Money(minorUnitAmount: lhs.centsAmount + rhs.centsAmount, currency: lhs.currency)
    }

    /// Adds one monetary amount to another.
    public static func += (lhs: inout Money, rhs: Money) {
        precondition(lhs.currency == rhs.currency)
        lhs = lhs + rhs
    }

    /// The difference between two monetary amounts.
    public static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency)
        return Money(minorUnitAmount: lhs.centsAmount - rhs.centsAmount, currency: lhs.currency)
    }

    /// Subtracts one monetary amount from another.
    public static func -= (lhs: inout Money, rhs: Money) {
        precondition(lhs.currency == rhs.currency)
        lhs = lhs - rhs
    }
}

extension Money {
    /// Negates the monetary amount.
    public static prefix func - (value: Money) -> Money {
        return Money(minorUnitAmount: -value.centsAmount, currency: value.currency)
    }

    public static func zero(_ currency: Currency) -> Money {
        .init(minorUnitAmount: 0, currency: currency)
    }
}

extension Money {
    /// The product of a monetary amount and a scalar value.
    public static func * (lhs: Money, rhs: Decimal) -> Money {
        let newValue = (Decimal(lhs.centsAmount) * rhs) as NSDecimalNumber
        return Money(minorUnitAmount: newValue.intValue, currency: lhs.currency)
    }

    /**
        The product of a monetary amount and a scalar value.

        - Important: Multiplying a monetary amount by a floating-point number
                     results in an amount rounded to the number of places
                     of the minor currency unit.
                     To produce a smaller fractional monetary amount,
                     multiply by a `Decimal` value instead.
     */
    public static func * (lhs: Money, rhs: Double) -> Money {
        return (lhs * Decimal(rhs)).rounded
    }

    /// The product of a monetary amount and a scalar value.
    public static func * (lhs: Money, rhs: Int) -> Money {
        return lhs * Decimal(rhs)
    }

    /// The product of a monetary amount and a scalar value.
    public static func * (lhs: Decimal, rhs: Money) -> Money {
        return rhs * lhs
    }

    /**
        The product of a monetary amount and a scalar value.

        - Important: Multiplying a monetary amount by a floating-point number
                     results in an amount rounded to the number of places
                     of the minor currency unit.
                     To produce a smaller fractional monetary amount,
                     multiply by a `Decimal` value instead.
     */
    public static func * (lhs: Double, rhs: Money) -> Money {
        return rhs * lhs
    }

    /// The product of a monetary amount and a scalar value.
    public static func * (lhs: Int, rhs: Money) -> Money {
        return rhs * lhs
    }

    /// Multiplies a monetary amount by a scalar value.
    public static func *= (lhs: inout Money, rhs: Decimal) {
        let newValue = (Decimal(lhs.centsAmount) * rhs) as NSDecimalNumber
        lhs = Money(minorUnitAmount: newValue.intValue, currency: lhs.currency)
    }

    /// Multiplies a monetary amount by a scalar value.
    /**
        Multiplies a monetary amount by a scalar value.

        - Important: Multiplying a monetary amount by a floating-point number
                     results in an amount rounded to the number of places
                     of the minor currency unit.
                     To produce a smaller fractional monetary amount,
                     multiply by a `Decimal` value instead.
     */
    public static func *= (lhs: inout Money, rhs: Double) {
        let newAmount = (Decimal(lhs.centsAmount) * Decimal(rhs)).rounded(for: lhs.currency)
        lhs = .init(majorUnitAmount: newAmount, currency: lhs.currency)
    }

    /// Multiplies a monetary amount by a scalar value.
    public static func *= (lhs: inout Money, rhs: Int) {
        let newAmount = lhs.centsAmount * rhs
        lhs = .init(minorUnitAmount: newAmount, currency: lhs.currency)
    }
}

// MARK: - CustomStringConvertible

extension Money: CustomStringConvertible {
    public var description: String {
        return "\(self.centsAmount)"
    }
}

// MARK: - Codable

/**
 Coding keys for `Money` values.
 */
public enum MoneyCodingKeys: String, CodingKey {
    /// The coding key for the `amount` property.
    case centsAmount

    /// The coding key for the `currencyCode` property
    case currencyCode
}

extension Money: Codable {
    public init(from decoder: Decoder) throws {

        if let keyedContainer = try? decoder.container(keyedBy: MoneyCodingKeys.self) {
            let currencyCode = try keyedContainer.decode(String.self, forKey: .currencyCode)
            guard let currencyValue = Currency.iso4217Currency(for: currencyCode) else {
                let context = DecodingError.Context(codingPath: keyedContainer.codingPath, debugDescription: "Unable to find a Currency with currencyCode - \(currencyCode)")
                throw DecodingError.typeMismatch(Money.self, context)
            }

            var amount: Int?
            if let string = try? keyedContainer.decode(String.self, forKey: .centsAmount) {
                amount = Int(string)
            }

            if let amount = amount {
                self.centsAmount = amount
                self.currency = currencyValue
            } else {
                throw DecodingError.dataCorruptedError(forKey: .centsAmount, in: keyedContainer, debugDescription: "Couldn't decode Decimal value for amount")
            }

        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Couldn't decode Money value")
            throw DecodingError.dataCorrupted(context)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var keyedContainer = encoder.container(keyedBy: MoneyCodingKeys.self)
        try keyedContainer.encode(currency.code, forKey: .currencyCode)
        try keyedContainer.encode(self.centsAmount, forKey: .centsAmount)
    }
}

// MARK:

extension Money {

    public enum Error: Swift.Error, CustomStringConvertible {
        case unsupportedCurrencyTextCode(String)
        case unsupportedCurrencyNumericCode(Int)
        case invalidDollarAmount(NSDecimalNumber)
        case unroundedAmount(Currency, NSDecimalNumber)
        case divideByZero
        case collectionMissingSufficientMoniesToSum
        case centsAmountIntOverflow

        public var description: String {
            switch self {
            case let .unsupportedCurrencyTextCode(code):
                return "Unsupported currency code \"\(code)\""
            case let .unsupportedCurrencyNumericCode(code):
                return "Unsupported currency code \"\(code)\""
            case let .invalidDollarAmount(amount):
                return "Invalid dollar amount \"\(amount)\""
            case let .unroundedAmount(currency, amount):
                return "Unrounded \(currency.code) amount \"\(amount)\""
            case .divideByZero:
                return "Divide by zero"
            case .collectionMissingSufficientMoniesToSum:
                return "Collection missing sufficient monies to sum"
            case .centsAmountIntOverflow:
                return "Cents amount overflowed when converting to Int"
            }
        }
    }

    private static func isValid(dollarAmount: NSDecimalNumber) -> Bool {
        return !(
               dollarAmount.isEqual(to: NSDecimalNumber.notANumber)
            || dollarAmount.isEqual(to: NSDecimalNumber.maximum)
            || dollarAmount.isEqual(to: NSDecimalNumber.minimum)
        )
    }
}


// MARK: -

fileprivate extension Decimal {
    func rounded(for currency: Currency) -> Decimal {
        var approximate = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &approximate, currency.minorUnit, .bankers)

        return rounded
    }
}
