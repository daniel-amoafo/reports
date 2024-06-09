
import MoneyCommon
import XCTest

final class MoneyFormatterTests: XCTestCase {

    // MARK: - Tests

    override func setUp() {
        super.setUp()
    }
    
    func testFormattingZero() {
        func assert(
            zeroAmount currency: Currency,
            formatter: MoneyFormatter,
            locale: Locale = .us,
            resultsIn expectedString: String
        ) {
            let amount = Money(minorUnitAmount: 0, currency: currency)
            let actualString = amount.localizedStringValue(formatter: formatter, locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(amount)"
            )
        }

        assert(zeroAmount: .USD, formatter: .standard, resultsIn: "$0.00")
        assert(zeroAmount: .USD, formatter: .compact, resultsIn: "$0")
        assert(zeroAmount: .USD, formatter: .accounting, resultsIn: "$0.00")

        // Test another locale
        assert(zeroAmount: .USD, formatter: .standard, locale: .fr, resultsIn: "$0,00")
        assert(zeroAmount: .USD, formatter: .compact, locale: .fr, resultsIn: "$0")
        assert(zeroAmount: .USD, formatter: .accounting, locale: .fr, resultsIn: "$0,00")

        // Test another currency
        assert(zeroAmount: .JPY, formatter: .standard, resultsIn: "¥0")
        assert(zeroAmount: .JPY, formatter: .compact, resultsIn: "¥0")
        assert(zeroAmount: .JPY, formatter: .centsOrCompact, resultsIn: "¥0")
        assert(zeroAmount: .JPY, formatter: .accounting, resultsIn: "¥0")

        assert(zeroAmount: .EUR, formatter: .standard, resultsIn: "€0.00")
        assert(zeroAmount: .EUR, formatter: .compact, resultsIn: "€0")
        assert(zeroAmount: .EUR, formatter: .centsOrCompact, resultsIn: "€0")
        assert(zeroAmount: .EUR, formatter: .accounting, resultsIn: "€0.00")

        // Also include a few custom formats.

        let positiveZeroFormatOptions = MoneyFormatter.Options(
            numberFormat: .unlocalized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: false,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: false
            ),
            signOption: .alwaysSigned,
            zeroBiasOption: .positive
        )

        assert(zeroAmount: .CAD, formatter: MoneyFormatter(options: positiveZeroFormatOptions), resultsIn: "+$0.00")

        let negativeZeroFormatOptions = MoneyFormatter.Options(
            numberFormat: .unlocalized,
            currencyRepresentationOption: .none,
            denominationOption: .dollar(
                omitsCentsIfPossible: true,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: false
            ),
            signOption: .alwaysSigned,
            zeroBiasOption: .negative
        )

        assert(zeroAmount: .USD, formatter: MoneyFormatter(options: negativeZeroFormatOptions), resultsIn: "-0")
    }

    func testStandardFormatting() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .standard, locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

        assert(money: usd("0.00"), resultsIn: "$0.00")
        assert(money: usd("1"), resultsIn: "$1.00")
        assert(money: usd("1.1"), resultsIn: "$1.10")
        assert(money: usd("1.01"), resultsIn: "$1.01")

        assert(money: usd("0.00"), locale: .fr, resultsIn: "$0,00")
        assert(money: usd("1"), locale: .fr, resultsIn: "$1,00")
        assert(money: usd("1.1"), locale: .fr, resultsIn: "$1,10")
        assert(money: usd("1.01"), locale: .fr, resultsIn: "$1,01")

    }

    func testReducedStandardFormatting() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .reducedStandard, locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

    }

    func testCodeFormatting() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .code, locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

        assert(money: usd("0.00"), resultsIn: "0.00 USD")
        assert(money: usd("1"), resultsIn: "1.00 USD")
        assert(money: usd("1.1"), resultsIn: "1.10 USD")
        assert(money: usd("1.01"), resultsIn: "1.01 USD")

        assert(money: usd("0.00"), locale: .fr, resultsIn: "0,00 USD")
        assert(money: usd("1"), locale: .fr, resultsIn: "1,00 USD")
        assert(money: usd("1.1"), locale: .fr, resultsIn: "1,10 USD")
        assert(money: usd("1.01"), locale: .fr, resultsIn: "1,01 USD")

    }

    func testSymbolAndCodeFormatting() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .symbolAndCode, locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

        assert(money: usd("0.00"), resultsIn: "$0.00 USD")
        assert(money: usd("1"), resultsIn: "$1.00 USD")
        assert(money: usd("1.1"), resultsIn: "$1.10 USD")
        assert(money: usd("1.01"), resultsIn: "$1.01 USD")

        assert(money: usd("0.00"), locale: .fr, resultsIn: "$0,00 USD")
        assert(money: usd("1"), locale: .fr, resultsIn: "$1,00 USD")
        assert(money: usd("1.1"), locale: .fr, resultsIn: "$1,10 USD")
        assert(money: usd("1.01"), locale: .fr, resultsIn: "$1,01 USD")
    }

    func testReducedCodeFormatting() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .reducedCode, locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

    }

    func testCompactFormatting() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .compact, locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

        assert(money: usd("0.00"), resultsIn: "$0")
        assert(money: usd("1"), resultsIn: "$1")
        assert(money: usd("1.1"), resultsIn: "$1.10")
        assert(money: usd("1.01"), resultsIn: "$1.01")

        assert(money: usd("0.00"), locale: .fr, resultsIn: "$0")
        assert(money: usd("1"), locale: .fr, resultsIn: "$1")
        assert(money: usd("1.1"), locale: .fr, resultsIn: "$1,10")
        assert(money: usd("1.01"), locale: .fr, resultsIn: "$1,01")

    }

    func testAbbreviatedFormattingDefault() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .abbreviated(), locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

        assert(money: usd("0.00"), resultsIn: "$0")
        assert(money: usd("100.00"), resultsIn: "$100")
        assert(money: usd("100.40"), resultsIn: "$100.40")
        assert(money: usd("100.70"), resultsIn: "$100.70")
        assert(money: usd("1000"), resultsIn: "$1K")
        assert(money: usd("1001"), resultsIn: "$1K")
        assert(money: usd("1175"), resultsIn: "$1.2K")
        assert(money: usd("1500.12"), resultsIn: "$1.5K")
        assert(money: usd("1000000"), resultsIn: "$1M")
        assert(money: usd("1640000"), resultsIn: "$1.6M")
        assert(money: usd("1000000000"), resultsIn: "$1B")
        assert(money: usd("1500000000"), resultsIn: "$1.5B")

        assert(money: usd("0.00"), locale: .fr, resultsIn: "$0")
        assert(money: usd("100.00"), locale: .fr, resultsIn: "$100")
        assert(money: usd("100.40"), locale: .fr, resultsIn: "$100,40")
        assert(money: usd("100.70"), locale: .fr, resultsIn: "$100,70")
        assert(money: usd("1000"), locale: .fr, resultsIn: "$1K")
        assert(money: usd("1001"), locale: .fr, resultsIn: "$1K")
        assert(money: usd("1175"), locale: .fr, resultsIn: "$1,2K")
        assert(money: usd("1500.12"), locale: .fr, resultsIn: "$1,5K")
        assert(money: usd("1000000"), locale: .fr, resultsIn: "$1M")
        assert(money: usd("1640000"), locale: .fr, resultsIn: "$1,6M")
        assert(money: usd("1000000000"), locale: .fr, resultsIn: "$1B")
        assert(money: usd("1500000000"), locale: .fr, resultsIn: "$1,5B")
    }

    func testAbbreviatedFormattingDown() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(formatter: .abbreviated(rounding: .down), locale: locale)
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

        assert(money: usd("0.00"), resultsIn: "$0")
        assert(money: usd("100.00"), resultsIn: "$100")
        assert(money: usd("100.40"), resultsIn: "$100.40")
        assert(money: usd("100.70"), resultsIn: "$100.70")
        assert(money: usd("1000"), resultsIn: "$1K")
        assert(money: usd("1001"), resultsIn: "$1K")
        assert(money: usd("1075"), resultsIn: "$1K")
        assert(money: usd("1100"), resultsIn: "$1.1K")
        assert(money: usd("1175"), resultsIn: "$1.1K")
        assert(money: usd("1500.12"), resultsIn: "$1.5K")
        assert(money: usd("1000000"), resultsIn: "$1M")
        assert(money: usd("1640000"), resultsIn: "$1.6M")
        assert(money: usd("1000000000"), resultsIn: "$1B")
        assert(money: usd("1500000000"), resultsIn: "$1.5B")

        assert(money: usd("0.00"), locale: .fr, resultsIn: "$0")
        assert(money: usd("100.00"), locale: .fr, resultsIn: "$100")
        assert(money: usd("100.40"), locale: .fr, resultsIn: "$100,40")
        assert(money: usd("100.70"), locale: .fr, resultsIn: "$100,70")
        assert(money: usd("1000"), locale: .fr, resultsIn: "$1K")
        assert(money: usd("1001"), locale: .fr, resultsIn: "$1K")
        assert(money: usd("1075"), locale: .fr, resultsIn: "$1K")
        assert(money: usd("1100"), locale: .fr, resultsIn: "$1,1K")
        assert(money: usd("1175"), locale: .fr, resultsIn: "$1,1K")
        assert(money: usd("1500.12"), locale: .fr, resultsIn: "$1,5K")
        assert(money: usd("1000000"), locale: .fr, resultsIn: "$1M")
        assert(money: usd("1640000"), locale: .fr, resultsIn: "$1,6M")
        assert(money: usd("1000000000"), locale: .fr, resultsIn: "$1B")
        assert(money: usd("1500000000"), locale: .fr, resultsIn: "$1,5B")
    }

    func testAbbreviatedFormattingUpToTwoFractionDigits() {
        func assert(money: Money, locale: Locale = .us, resultsIn expectedString: String) {
            let actualString = money.localizedStringValue(
                formatter: .abbreviated(fractionDigitsStrategy: .upToTwoDigits),
                locale: locale
            )
            XCTAssert(
                actualString == expectedString,
                "Incorrect format \"\(actualString)\" instead of \"\(expectedString)\" for \(money)"
            )
        }

        assert(money: usd("0.00"), resultsIn: "$0")
        assert(money: usd("100.00"), resultsIn: "$100")
        assert(money: usd("100.40"), resultsIn: "$100.40")
        assert(money: usd("100.70"), resultsIn: "$100.70")
        assert(money: usd("1000"), resultsIn: "$1K")
        assert(money: usd("1001"), resultsIn: "$1K")
        assert(money: usd("1175"), resultsIn: "$1.18K")
        assert(money: usd("1500"), resultsIn: "$1.5K")
        assert(money: usd("1000000"), resultsIn: "$1M")
        assert(money: usd("1640000"), resultsIn: "$1.64M")
        assert(money: usd("1000000000"), resultsIn: "$1B")
        assert(money: usd("1456700000"), resultsIn: "$1.46B")
        assert(money: usd("1500000000"), resultsIn: "$1.5B")
        assert(money: usd("1523400000"), resultsIn: "$1.52B")
        assert(money: usd("1992000000"), resultsIn: "$1.99B")
        assert(money: usd("1999900000"), resultsIn: "$2B")
        assert(money: usd("2000000000"), resultsIn: "$2B")
        assert(money: usd("2575000000"), resultsIn: "$2.58B")
        assert(money: usd("140000000000"), resultsIn: "$140B")
        assert(money: usd("140000000001"), resultsIn: "$140B")
        assert(money: usd("140100000001"), resultsIn: "$140.1B")

        assert(money: usd("0.00"), locale: .fr, resultsIn: "$0")
        assert(money: usd("100.00"), locale: .fr, resultsIn: "$100")
        assert(money: usd("100.40"), locale: .fr, resultsIn: "$100,40")
        assert(money: usd("100.70"), locale: .fr, resultsIn: "$100,70")
        assert(money: usd("1000"), locale: .fr, resultsIn: "$1K")
        assert(money: usd("1001"), locale: .fr, resultsIn: "$1K")
        assert(money: usd("1175"), locale: .fr, resultsIn: "$1,18K")
        assert(money: usd("1500"), locale: .fr, resultsIn: "$1,5K")
        assert(money: usd("1000000"), locale: .fr, resultsIn: "$1M")
        assert(money: usd("1640000"), locale: .fr, resultsIn: "$1,64M")
        assert(money: usd("1000000000"), locale: .fr, resultsIn: "$1B")
        assert(money: usd("1500000000"), locale: .fr, resultsIn: "$1,5B")
        assert(money: usd("1520000000"), locale: .fr, resultsIn: "$1,52B")
        assert(money: usd("2000000000"), locale: .fr, resultsIn: "$2B")
        assert(money: usd("2575000000"), locale: .fr, resultsIn: "$2,58B")
        assert(money: usd("140000000000"), locale: .fr, resultsIn: "$140B")
        assert(money: usd("140000000001"), locale: .fr, resultsIn: "$140B")
        assert(money: usd("140100000001"), locale: .fr, resultsIn: "$140,1B")
    }

    // MARK: - Helper Methods

    private func usd(_ amount: String) -> Money {
        return Money(majorUnitAmount: Decimal(string: amount)!, currency: .USD)
    }

    private func jpy(_ amount: String) -> Money {
        return Money(majorUnitAmount: Decimal(string: amount)!, currency: .JPY)
    }

    private func cad(_ amount: String) -> Money {
        return Money(majorUnitAmount: Decimal(string: amount)!, currency: .CAD)
    }

    private func kwd(_ amount: String) -> Money {
        return Money(majorUnitAmount: Decimal(string: amount)!, currency: .KWD)
    }

    private func gbp(_ amount: String) -> Money {
        return Money(majorUnitAmount: Decimal(string: amount)!, currency: .GBP)
    }

    private func eur(_ amount: String) -> Money {
        return Money(majorUnitAmount: Decimal(string: amount)!, currency: .EUR)
    }
}

// MARK: -

private extension Locale {
    static let us = Locale(identifier: "en_US")
    static let fr = Locale(identifier: "fr_FR")
}
