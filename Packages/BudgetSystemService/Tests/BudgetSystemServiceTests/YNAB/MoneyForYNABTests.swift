// Created by Daniel Amoafo on 24/4/2024.

@testable import BudgetSystemService
import Foundation
import MoneyCommon
import XCTest

final class MoneyForYNAB: XCTestCase {

    func testMoneyWithMilliUnitValues() {

        // A currency with a minor units of 0 e.g. Japaness YEN
        let currencyZeroMinorUnits = Money.forYNAB(amount: 110000, currency: .JPY)
        XCTAssertEqual(currencyZeroMinorUnits.amount, Decimal(110))

        // A currency with a minor units of 2 e.g. US Dollars, with cents defined
        let currency2MinorUnits = Money.forYNAB(amount: 25990, currency: .USD)
        XCTAssertEqual(currency2MinorUnits.amount, Decimal(2599))

        // A currency with a minor units of 2 e.g. US Dollars, the value has no cents
        let currency2MinorUnitsZeroed = Money.forYNAB(amount: 25000, currency: .USD)
        XCTAssertEqual(currency2MinorUnitsZeroed.amount, Decimal(2500))

        // A currency with a minor units of 3 e.g. Jordanian Dinar, with fils defined
        let currency3MinorUnits = Money.forYNAB(amount: 123456, currency: .JOD)
        XCTAssertEqual(currency3MinorUnits.amount, Decimal(123456))

        // A currency with a minor units of 3 e.g. Jordanian Dinar, with no fils defined
        let currency3MinorUnitsZeroed = Money.forYNAB(amount: 123000, currency: .JOD)
        XCTAssertEqual(currency3MinorUnitsZeroed.amount, Decimal(123000))
    }
}
