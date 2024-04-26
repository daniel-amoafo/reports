import XCTest
@testable import MoneyCommon

final class MoneyTests: XCTestCase {

    func testMonetaryCalculations() {
        let prices = [
            2.19, 5.39, 20.99, 2.99, 1.99, 1.99, 0.99
        ].map { Money(.init($0), currency: .USD) }

        let subtotal = prices.reduce(Money.zero(.USD), +)
        let tax = 0.08 * subtotal
        let total = subtotal + tax

        XCTAssertEqual(subtotal.amount, Decimal(string: "36.53", locale: nil))
        XCTAssertEqual(tax.amount, Decimal(string: "2.92", locale: nil))
        XCTAssertEqual(total.amount, Decimal(string: "39.45", locale: nil))
    }


    func testFormattedCurrencyAmounts() {

        // values are represented in milliunits e.g. 100 -> $1 USD, 100 -> ¥100 JPY
        let values = [100, 1500, 1699, 12345, 9_999_99, 100_000_46]

        // USD
        let usdValues = values
            .map { Money(.init($0), currency: .USD).stringFormatted(locale: .init(identifier: "en_US")) }

        XCTAssertEqual(usdValues[0], "$1.00")
        XCTAssertEqual(usdValues[1], "$15.00")
        XCTAssertEqual(usdValues[2], "$16.99")
        XCTAssertEqual(usdValues[3], "$123.45")
        XCTAssertEqual(usdValues[4], "$9,999.99")
        XCTAssertEqual(usdValues[5], "$100,000.46")

        // JPY
        let jpyValues = values
            .map { Money(.init($0), currency: .JPY).stringFormatted(locale: .init(identifier: "ja_JP")) }
        XCTAssertEqual(jpyValues[0], "¥100")
        XCTAssertEqual(jpyValues[1], "¥1,500")
        XCTAssertEqual(jpyValues[2], "¥1,699")
        XCTAssertEqual(jpyValues[3], "¥12,345")
        XCTAssertEqual(jpyValues[4], "¥999,999")
        XCTAssertEqual(jpyValues[5], "¥10,000,046")

        // Euros
        let eurosValues = values
            .map { Money(.init($0), currency: .EUR).stringFormatted(locale: .init(identifier: "fr_FR")) }
        XCTAssertEqual(eurosValues[0], "1,00 €")
        XCTAssertEqual(eurosValues[1], "15,00 €")
        XCTAssertEqual(eurosValues[2], "16,99 €")
        XCTAssertEqual(eurosValues[3], "123,45 €")
        XCTAssertEqual(eurosValues[4], "9 999,99 €")
        XCTAssertEqual(eurosValues[5], "100 000,46 €")
    }
}
