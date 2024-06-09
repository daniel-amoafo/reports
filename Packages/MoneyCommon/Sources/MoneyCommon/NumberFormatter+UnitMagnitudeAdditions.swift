import Foundation

private protocol UnitMagnitude {

    static var abbreviated: String { get }

    static var full: String { get }

}

// MARK: -

extension UnitMagnitude {

    static func string(for unitMagnitudeFormat: NumberFormatter.UnitMagnitudeFormat) -> String {
        switch unitMagnitudeFormat {
        case .abbreviated: return abbreviated
        case .full: return full
        }
    }

}

// MARK: -

extension NumberFormatter {

    // MARK: - Public Types

    /// The format of unit magnitude string to apply at the end of the abbreviated string for a given number.
    public enum UnitMagnitudeFormat {
        /// An abbreviated version of the unit magnitude to apply when formatting, ie. the "M" in "10.5M"
        case abbreviated

        /// An full version of the unit magnitude to apply when formatting, ie. the "Million" in "10.5 Million"
        case full
    }

    // MARK: - Private Types

    /// A rule type used in determining when/how to abbreviate values. See numberAbbreviationRules below for an example.
    private struct AbbreviationRule {
        /// Rule can apply if a value is greater than this threshold.
        var threshold: Double

        /// The amount to divide the value by when formatting it.
        var divisor: Double

        /// Unit magnitude text to apply when formatting, ie. the "M" in "10.5M" or "Million" in "10.5 Million".
        var unitMagnitude: UnitMagnitude.Type?
    }

    // swiftlint:disable line_length
    private enum Strings {
        enum Thousand: UnitMagnitude {
            static let abbreviated = String(localized: "K", comment: "Abbreviated thousand unit magnitude for abbreviated numbers, ie the K in '1.1K'")
            static let full = String(localized: "Thousand", comment: "Full thousand unit magnitude for abbreviated numbers, ie the Thousand in '1.1 Thousand'")
        }

        enum Million: UnitMagnitude {
            static let abbreviated = String(localized: "M", comment: "Abbreviated million unit magnitude for abbreviated numbers, ie the M in '1.1M'")
            static let full = String(localized: "Million", comment: "Full million unit magnitude for abbreviated numbers, ie the Million in '1.1 Million'")
        }

        enum Billion: UnitMagnitude {
            static let abbreviated = String(localized: "B", comment: "Abbreviated billion unit magnitude for abbreviated numbers, ie the B in '1.1B'")
            static let full = String(localized: "Billion", comment: "Full billion unit magnitude for abbreviated numbers, ie the Billion in '1.1 Billion'")
        }

        enum Trillion: UnitMagnitude {
            static let abbreviated = String(localized: "T", comment: "Abbreviated trillion unit magnitude for abbreviated numbers, ie the T in '1.1T'")
            static let full = String(localized: "Trillion", comment: "Full trillion unit magnitude for abbreviated numbers, ie the Trillion in '1.1 Trillion'")
        }

        static func abbreviatedNumberWithUnitMagnitudeFormatString(unitMagnitudeFormat: UnitMagnitudeFormat) -> String {
            switch unitMagnitudeFormat {
            case .abbreviated:
                return String(localized: "%@%@",
                    comment: "Format string for displaying an abbreviated number with an abbreviated unit magnitude, i.e. '1.1K'. arg1: abbreviated number, arg1: abbreviated unit magnitude."
                )
            case .full:
                return String(localized: "%@ %@",
                    comment: "Format string for displaying an abbreviated number with a unit magnitude, i.e. '1.1 Thousand'. arg1: abbreviated number, arg1: unit magnitude."
                )
            }
        }
    }
    // swiftlint:enable line_length

    // MARK: - Private Properties

    private var numberAbbreviationRules: [AbbreviationRule] {
        return [
            AbbreviationRule(threshold: 0, divisor: 1, unitMagnitude: nil),
            AbbreviationRule(threshold: 1_000, divisor: 1_000, unitMagnitude: Strings.Thousand.self),
            AbbreviationRule(threshold: 1_000_000, divisor: 1_000_000, unitMagnitude: Strings.Million.self),
            AbbreviationRule(threshold: 1_000_000_000, divisor: 1_000_000_000, unitMagnitude: Strings.Billion.self),
            AbbreviationRule(
                threshold: 1_000_000_000_000,
                divisor: 1_000_000_000_000,
                unitMagnitude: Strings.Trillion.self
            ),
        ]
    }

    // MARK: - Public Categories

    @objc(cc_percentageStringFromBasisPoints:)
    public static func percentageString(from basisPoints: Int) -> String {
        return percentageString(from: basisPoints, hideSignPrefix: false)
    }

    public static func percentageString(
        from basisPoints: Int,
        hideSignPrefix: Bool
    ) -> String {
        updatePercentageFormatter(forBasisPoints: basisPoints, hideSignPrefix: hideSignPrefix)
        return percentageFormatter.string(for: Double(basisPoints) / 10_000)!
    }

    /**
     The abbreviated string from the number applying the abbreviation rules for each threshold power of ten.
     - parameter number: The number to be formatted and abbreviated
     - parameter fractionDigitsStrategy: Decribes how many fraction digits should be present in the abbreviated result.
     Defaults to `nil`, which relies on the cosumer to set fraction digits values.
     - parameter unitMagnitudeFormat: The format of unit to append to the end of the abbreviated number.
     */
    public func abbreviatedString(
        from number: NSNumber,
        fractionDigitsStrategy: MoneyFormatter.FractionDigitsStrategy? = nil,
        unitMagnitudeFormat: UnitMagnitudeFormat = .abbreviated
    ) -> String {
        let doubleValue = number.doubleValue

        // This abbreviation technique is inspired by <http://stackoverflow.com/a/35504720>.
        var abbreviationRuleForAmount = numberAbbreviationRules[0]
        for rule in numberAbbreviationRules {
            if fabs(doubleValue) < rule.threshold {
                break
            }

            abbreviationRuleForAmount = rule
        }

        let valueToFormat = (doubleValue / abbreviationRuleForAmount.divisor) as NSNumber

        // swiftlint:disable:next force_cast
        let formatter = copy() as! NumberFormatter

        if let fractionDigitsStrategy = fractionDigitsStrategy {
            switch fractionDigitsStrategy {
            case let .exactNumberBetween(minimumFractionDigits, maximumFractionDigits):
                formatter.minimumFractionDigits = minimumFractionDigits
                formatter.maximumFractionDigits = maximumFractionDigits

            case .upToTwoDigits:
                // show maximum of two digits by default: xx.xx
                formatter.maximumFractionDigits = 2

                if formatter.string(from: valueToFormat)!.count == 6 { // xxx.xx
                    formatter.maximumFractionDigits = 1 // xxx.x
                }
            }
        }

        let formattedNumber = formatter.string(from: valueToFormat)!

        if let unitMagnitude = abbreviationRuleForAmount.unitMagnitude?.string(for: unitMagnitudeFormat) {
            let formatString = Strings.abbreviatedNumberWithUnitMagnitudeFormatString(
                unitMagnitudeFormat: unitMagnitudeFormat
            )
            return String(format: formatString, formattedNumber, unitMagnitude)
        } else {
            return formattedNumber
        }
    }

    // MARK: - Private Methods

    private static func updatePercentageFormatter(forBasisPoints basisPoints: Int, hideSignPrefix: Bool) {
        let maximumFractionDigits: Int
        if basisPoints % 100 == 0 {
            // Whole percentage (e.g. 1%): show no decimal amount.
            maximumFractionDigits = 0
        } else if basisPoints % 10 == 0 {
            // One-tenth percentage (e.g. 1.5%): show one decimal digit.
            maximumFractionDigits = 1
        } else {
            // One-hundredth percentage (e.g. 1.25%): show two decimal digits.
            maximumFractionDigits = 2
        }
        percentageFormatter.maximumFractionDigits = maximumFractionDigits

        if hideSignPrefix {
            percentageFormatter.positivePrefix = ""
            percentageFormatter.negativePrefix = ""
        }
    }

}

private let percentageFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.minimumFractionDigits = 0
    return formatter
}()
