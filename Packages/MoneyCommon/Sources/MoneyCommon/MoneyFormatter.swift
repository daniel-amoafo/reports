// Created by Daniel Amoafo on 7/6/2024.

import Foundation

public struct MoneyFormatter: CustomDebugStringConvertible, Sendable {

    // MARK: - Types

    public struct Options: CustomDebugStringConvertible, Sendable {

        // MARK: - Types

        public enum CurrencyRepresentationOption: Sendable {
            /// The currency's symbol, e.g. $ or ¥
            case symbol

            /// The currency's ISO code, e.g. USD or JPY
            case code

            /// Both the symbol and the ISO code, e.g. "$123 USD"
            case symbolAndCode

            /// Don't show the currency at all (i.e. just the amount)
            case none
        }

        public enum DenominationOption: Sendable {
            /// Show the money as its cent value
            case cents

            /// Show the amount as its dollar value with options for cents
            ///
            /// - Parameters:
            ///     - omitsCentsIfPossible: Display whole-dollar amounts without a decimal and cents.
            ///     - reduceCentsToMinimumSignificatDigits: Reduce cents to minimum significant
            ///       digits by removing extra zero (e.g., 0.15400000 BTC -> 0.154 BTC)
            ///     - showsAsCentsIfPossible: Display sub-$1 amounts as a whole number of cents
            ///       (for currencies with a cents symbol)
            case dollar(
                omitsCentsIfPossible: Bool,
                reduceCentsToMinimumSignificantDigits: Bool,
                showsAsCentsIfPossible: Bool
            )
        }

        public enum SignOption: Sendable {
            /// Show a minus sign for negative numbers only
            case standard

            /// Show a minus sign for negative numbers and a plus sign for positive numbers
            case alwaysSigned

            /// Show a plus sign for positive numbers, and nothing for negative numbers
            case positiveOnly

            /// Enclose negative numbers in parentheses
            case accounting

            /// Do not indicate the sign (e.g. when using color to show credit vs. debit)
            case none
        }

        public enum ZeroBiasOption: Sendable {
            /// Do not show +/- for zero amounts
            case none

            /// Show zero amounts as negative
            case negative

            /// Show zero amounts as positive
            case positive
        }

        public enum NumberFormat: Sendable {
            /// Use the current locale's formatting options for the number (e.g. decimal and grouping separators)
            case localized

            /// Abbreviate the number (ie. $1100 becomes 1.1K, $5,000,000 becomes $5M)
            /// - parameter roundingMode: How the number should be rounded, if necessary, in order to be abbreviated.
            /// - parameter minimumFractionDigits: The minimum number of digits after the decimal separator.
            /// - parameter maximumFractionDigits: The maximum number of digits after the decimal separator.
            /// - parameter unitMagnitudeFormat: How the unit magnitude should be formatted.
            /// - parameter threshold: At which value the number should start being rounded.
            case localizedAbbreviated(
                roundingMode: NumberFormatter.RoundingMode,
                fractionDigitsStrategy: FractionDigitsStrategy,
                unitMagnitudeFormat: NumberFormatter.UnitMagnitudeFormat,
                threshold: NSDecimalNumber
            )

            /// Do not localize the number
            case unlocalized
        }

        // MARK: - Instance Properties/Types

        /// Use the current locale's formatting options for the number (e.g. decimal and grouping separators)
        public let numberFormat: NumberFormat

        /// Display option for the currency symbol (see enum cases)
        public let currencyRepresentationOption: CurrencyRepresentationOption

        /// Display option for the denomination representation
        public let denominationOption: DenominationOption

        /// Display option for the sign (see enum cases)
        public let signOption: SignOption

        /// Display option for zero amount sign treatment (see enum cases)
        public let zeroBiasOption: ZeroBiasOption

        // MARK: - Static Properties

        public static let localizedMinusSign = "−"      // U+2212, "minus sign"
        public static let unlocalizedMinusSign = "-"    // U+002D, "hyphen-minus"
        public static let plusSign = "+"

        // MARK: - CustomDebugStringConvertible

        public var debugDescription: String {
            let symbolString: String

            switch denominationOption {
            case let .dollar(omitsCentsIfPossible, _, showsAsCentsIfPossible):
                switch currencyRepresentationOption {
                case .symbol:
                    if omitsCentsIfPossible {
                        symbolString = showsAsCentsIfPossible ? "$_/_¢" : "$_/$."
                    } else {
                        symbolString = showsAsCentsIfPossible ? "$./_¢" : "$_.00"
                    }
                case .code:
                    if omitsCentsIfPossible {
                        symbolString = showsAsCentsIfPossible ? "X_/_¢" : "X_/$."
                    } else {
                        symbolString = showsAsCentsIfPossible ? "X./_¢" : "X_.00"
                    }
                case .symbolAndCode:
                    if omitsCentsIfPossible {
                        symbolString = showsAsCentsIfPossible ? "$X_/_¢" : "$X_/$."
                    } else {
                        symbolString = showsAsCentsIfPossible ? "$X./_¢" : "$X_.00"
                    }
                case .none:
                    // The showAsCentsIfPossible option doesn't apply to the omit-currency-symbol case.
                    symbolString = omitsCentsIfPossible ? "_X___" : "_X.00"
                }
            case .cents:
                switch currencyRepresentationOption {
                case .symbol, .code, .symbolAndCode, .none:
                    symbolString = "X_/_¢"
                }
            }

            let signOptionString: String
            switch signOption {
            case .standard:
                signOptionString = "-_"
            case .alwaysSigned:
                signOptionString = "-+"
            case .positiveOnly:
                signOptionString = "_+"
            case .accounting:
                signOptionString = "()"
            case .none:
                signOptionString = "__"
            }

            let zeroBiasOptionString: String
            switch zeroBiasOption {
            case .none:
                zeroBiasOptionString = " 0"
            case .negative:
                zeroBiasOptionString = "-0"
            case .positive:
                zeroBiasOptionString = "+0"
            }

            return "MoneyFormat(\(symbolString), \(signOptionString), \(zeroBiasOptionString))"
        }

        public init(
            numberFormat: NumberFormat,
            currencyRepresentationOption: CurrencyRepresentationOption,
            denominationOption: DenominationOption,
            signOption: SignOption,
            zeroBiasOption: ZeroBiasOption
        ) {
            self.numberFormat = numberFormat
            self.currencyRepresentationOption = currencyRepresentationOption
            self.denominationOption = denominationOption
            self.signOption = signOption
            self.zeroBiasOption = zeroBiasOption
        }

    }

    /// Describes how many fraction digits should be present in the abbreviated result.
    public enum FractionDigitsStrategy: Sendable {
        /// Contains a specified amount of fraction digits.
        /// - parameter minimum: The minimum number of digits after the decimal separator.
        /// Defaults to `0`.
        /// - parameter maximum: The maximum number of digits after the decimal separator.
        /// Defaults to `1`.
        case exactNumberBetween(minimum: Int = 0, maximum: Int = 1)
        /// Contains up to two fraction digits: x.[x, xx], xx.[x, xx], xxx.[x].
        /// If the number of whole digits is 1 or 2, the number of fraction digits is 2.
        /// If the number of whole digits is 3, the number of fraction digits is 1.
        case upToTwoDigits
    }

    // MARK: - Static Instances

    /// Typical display of dollars and cents, e.g. "$25.00" or "¥1,000"
    public static let standard = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: false,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: false
            ),
            signOption: .standard,
            zeroBiasOption: .none
        )
    )

    /// Typical display of reduced dollars and cents, e.g. "₿1.5".
    /// Should only be used with non-cent based currencies like Bitcoin where trailing zeros can be ommited.
    public static let reducedStandard = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: true,
                reduceCentsToMinimumSignificantDigits: true,
                showsAsCentsIfPossible: false
            ),
            signOption: .standard,
            zeroBiasOption: .none
        )
    )

    /// Typical display of dollars and cents with currency code, e.g., "25.00 USD" or "1.50000000 BTC"
    public static let code = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .code,
            denominationOption: .dollar(
                omitsCentsIfPossible: false,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: false
            ),
            signOption: .standard,
            zeroBiasOption: .none
        )
    )

    /// Typical display of dollars and cents, with both a currency symbol and a currency code, e.g. "$25.00 USD"
    public static let symbolAndCode = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbolAndCode,
            denominationOption: .dollar(
                omitsCentsIfPossible: false,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: false
            ),
            signOption: .standard,
            zeroBiasOption: .none
        )
    )

    /// Typical display of reduced dollars and cents with currency code, e.g., "1.5 BTC".
    /// Should only be used with non-cent based currencies like Bitcoin where trailing zeros can be ommited.
    public static let reducedCode = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .code,
            denominationOption: .dollar(
                omitsCentsIfPossible: false,
                reduceCentsToMinimumSignificantDigits: true,
                showsAsCentsIfPossible: false
            ),
            signOption: .standard,
            zeroBiasOption: .none
        )
    )

    /// Typical display of dollars only, or dollars and cents, e.g. "$25" or "$24.99"
    public static let compact = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: true,
                reduceCentsToMinimumSignificantDigits: true,
                showsAsCentsIfPossible: false
            ),
            signOption: .standard,
            zeroBiasOption: .none
        )
    )

    /// Typical display of dollars only, or dollars and cents, e.g. "+$25" or "+$24.99",
    /// no sign is shown with negative numbers
    public static let compactPositiveSignOnly = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: true,
                reduceCentsToMinimumSignificantDigits: true,
                showsAsCentsIfPossible: false
            ),
            signOption: .positiveOnly,
            zeroBiasOption: .none
        )
    )

    /// Typical display for (usually small) fees, e.g. "25¢", "$1", or "$1.05"
    public static let centsOrCompact = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: true,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: true
            ),
            signOption: .standard,
            zeroBiasOption: .none
        )
    )

    /// Typical display for an accounting ledger, e.g. "($25.00)" or "$25.00"
    /// for negative and positive values, respectively.
    public static let accounting = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: false,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: false
            ),
            signOption: .accounting,
            zeroBiasOption: .none
        )
    )

    /// Display of abbreviated dollars rounded with the given rounding mode,  with cents ommitted,
    /// eg. "$5", "$1.1K" or "$1.5M".
    /// - parameter signOption: Indicate if number is prefixed with positive +, negative - or no symbol. Deatuls to `.standard`.
    /// - parameter threshold:
    /// - parameter roundingMode: How the number should be rounded, if necessary, in order to be abbreviated.
    ///   Defaults to `.halfEven`.
    /// - parameter fractionDigitsStrategy: The strategy to define number of digits after the decimal separator.
    /// Defaults to the exact number between `minimum: 0` and `maximum: 1`.
    public static func abbreviated(
        signOption: Options.SignOption = .standard,
        threshold: NSDecimalNumber = 1000,
        rounding roundingMode: NumberFormatter.RoundingMode = .halfEven,
        fractionDigitsStrategy: FractionDigitsStrategy = .exactNumberBetween(minimum: 0, maximum: 1)
    ) -> MoneyFormatter {
        return MoneyFormatter(
            options: Options(
                numberFormat: .localizedAbbreviated(
                    roundingMode: roundingMode,
                    fractionDigitsStrategy: fractionDigitsStrategy,
                    unitMagnitudeFormat: .abbreviated,
                    threshold: threshold
                ),
                currencyRepresentationOption: .symbol,
                denominationOption: .dollar(
                    omitsCentsIfPossible: true,
                    reduceCentsToMinimumSignificantDigits: false,
                    showsAsCentsIfPossible: false
                ),
                signOption: signOption,
                zeroBiasOption: .none
            )
        )
    }

    // MARK: - Public Properties

    public let options: Options

    // MARK: - Life Cycle

    public init(options: Options) {
        self.options = options
    }

    // MARK: - Public Functions

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    public func stringValue(
        for amount: Money,
        locale: Locale
    ) -> String {

        func amountIsBelowOneDollar() -> Bool {
            let oneDollar = Money(majorUnitAmount: 1, currency: amount.currency)
            return (amount < oneDollar)
        }

        let number: NSDecimalNumber
        let showFractionalAmount: Bool

        // Dollars, with or without cents as appropriate.
        number = amount.toMajorUnitAmount
        switch options.denominationOption {
        case let .dollar(omitsCentsIfPossible, _, _):
            showFractionalAmount = !(amount.isWholeDollarAmount && omitsCentsIfPossible)
        case .cents:
            showFractionalAmount = false
        }

        let fractionDigits = showFractionalAmount ? amount.currency.minorUnit : 0
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumIntegerDigits = 1

        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits

        var formattedString: String

        switch options.numberFormat {
        case .localized:
            formatter.usesGroupingSeparator = true
            formatter.groupingSize = 3
            formattedString = formatter.string(for: number)!

        case let .localizedAbbreviated(
            roundingMode,
            fractionDigitsStrategy,
            unitMagnitudeFormat,
            threshold
        ):
            if number.compare(threshold) == .orderedDescending || number.isEqual(threshold) {
                formatter.roundingMode = roundingMode
                formattedString = formatter.abbreviatedString(
                    from: number,
                    fractionDigitsStrategy: fractionDigitsStrategy,
                    unitMagnitudeFormat: unitMagnitudeFormat
                )
            } else {
                formatter.usesGroupingSeparator = true
                formatter.groupingSize = 3
                formattedString = formatter.string(for: number)!
            }

        case .unlocalized:
            formatter.usesGroupingSeparator = false
            formatter.decimalSeparator = "."
            formattedString = formatter.string(for: number)!
        }

        // Next, add the currency symbol as appropriate.

        switch options.currencyRepresentationOption {
        case .symbol, .symbolAndCode:
            formattedString = amount.currency.symbol + formattedString
        case .code, .none:
            break
        }

        // Then, show the sign.

        let centsAmount = amount.centsAmount
        if (centsAmount < 0) || (centsAmount == 0 && options.zeroBiasOption == .negative) {
            switch options.signOption {
            case .standard, .alwaysSigned:
                switch options.numberFormat {
                case .localized, .localizedAbbreviated:
                    formattedString = Options.localizedMinusSign + formattedString

                case .unlocalized:
                    formattedString = Options.unlocalizedMinusSign + formattedString
                }
            case .accounting:
                formattedString = "(" + formattedString + ")"
            case .none, .positiveOnly:
                break
            }

        } else if (centsAmount > 0) || (centsAmount == 0 && options.zeroBiasOption == .positive) {
            switch options.signOption {
            case .alwaysSigned, .positiveOnly:
                formattedString = Options.plusSign + formattedString
            case .standard, .accounting, .none:
                break
            }
        }

        // Finally, add the currency code if designated.

        switch options.currencyRepresentationOption {
        case .code, .symbolAndCode:
            formattedString = formattedString + " " + amount.currency.code
        case .symbol, .none:
            break
        }

        return formattedString
    }
    // swiftling:enable cyclomatic_complexity
    // swiftling:enable function_body_length

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        return options.debugDescription
    }

}

// MARK: - Money Extension

extension Money {

    public func localizedStringValue(
        formatter: MoneyFormatter = .standard,
        locale: Locale
    ) -> String {
        return formatter.stringValue(for: self, locale: locale)
    }

}
