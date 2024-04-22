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


}

