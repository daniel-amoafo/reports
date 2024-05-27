// This file is based on https://github.com/Flight-School/Money project
import Foundation

/// An amount of money in a given currency.
public struct Money: Equatable, Hashable {

    /// The amount of money.
    public let amount: Decimal
    public let currency: Currency

    /// Creates an amount of money with a given decimal number.
    public init(_ amount: Decimal, currency: Currency) {
        self.amount = amount
        self.currency = currency
    }

    /**
        A monetary amount rounded to
        the number of places of the minor currency unit.
     */
    public var rounded: Money {
        return Money(amount.rounded(for: currency), currency: currency)
    }
}

// MARK: - Conversion

public extension Money {

    /// Converts to minor unit amount  e.g. dollars to cents, 1.00 -> 100 for USD.
    var toMinorUnitAmount: NSDecimalNumber {
        return (amount as NSDecimalNumber).multiplying(byPowerOf10: Int16(currency.minorUnit))
    }

    /// Converts to major unit amount e.g. cents to dollars, e.g. 100 -> 1.00 for USD.
    var toMajorUnitAmount: NSDecimalNumber {
        return (amount as NSDecimalNumber).multiplying(byPowerOf10: Int16(-currency.minorUnit))
    }
}

// MARK: - Formatting

public extension Money {
    
    var amountFormatted: String {
        let formatter = CurrencyFormatter.formatter(for: currency)
        return formatter.string(for: toMajorUnitAmount) ?? ""
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
        return Money(lhs.amount + rhs.amount, currency: lhs.currency)
    }

    /// Adds one monetary amount to another.
    public static func += (lhs: inout Money, rhs: Money) {
        precondition(lhs.currency == rhs.currency)
        lhs = lhs + rhs
    }

    /// The difference between two monetary amounts.
    public static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency)
        return Money(lhs.amount - rhs.amount, currency: lhs.currency)
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
        return Money(-value.amount, currency: value.currency)
    }

    public static func zero(_ currency: Currency) -> Money {
        .init(.zero, currency: currency)
    }
}

extension Money {
    /// The product of a monetary amount and a scalar value.
    public static func * (lhs: Money, rhs: Decimal) -> Money {
        return Money(lhs.amount * rhs, currency: lhs.currency)
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
        lhs = Money(lhs.amount * rhs, currency: lhs.currency)
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
        let newAmount = (lhs.amount * Decimal(rhs)).rounded(for: lhs.currency)
        lhs = .init(newAmount, currency: lhs.currency)
    }

    /// Multiplies a monetary amount by a scalar value.
    public static func *= (lhs: inout Money, rhs: Int) {
        let newAmount = (lhs.amount * Decimal(rhs)).rounded(for: lhs.currency)
        lhs = .init(newAmount, currency: lhs.currency)
    }
}

// MARK: - CustomStringConvertible

extension Money: CustomStringConvertible {
    public var description: String {
        return "\(self.amount)"
    }
}

// MARK: - Codable

/**
 Coding keys for `Money` values.
 */
public enum MoneyCodingKeys: String, CodingKey {
    /// The coding key for the `amount` property.
    case amount

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

            var amount: Decimal?
            if let string = try? keyedContainer.decode(String.self, forKey: .amount) {
                amount = Decimal(string: string)
            }

            if let amount = amount {
                self.amount = amount
                self.currency = currencyValue
            } else {
                throw DecodingError.dataCorruptedError(forKey: .amount, in: keyedContainer, debugDescription: "Couldn't decode Decimal value for amount")
            }

        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Couldn't decode Money value")
            throw DecodingError.dataCorrupted(context)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var keyedContainer = encoder.container(keyedBy: MoneyCodingKeys.self)
        try keyedContainer.encode(currency.code, forKey: .currencyCode)
        try keyedContainer.encode(self.amount, forKey: .amount)
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
