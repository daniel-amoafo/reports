// Created by Daniel Amoafo on 8/6/2024.

import Foundation

public extension Currency {

    var symbol: String {
        guard let symbol = CurrencySymbol.currency(for: code) else {
            debugPrint("Unable to find currency symbol for code: \(code)")
            return ""
        }
        return symbol.shortestSymbol
    }

    var centsPerDollar: Int {
        return minorUnitAmount(fromMajorUnitAmount: .one).intValue
    }

    func majorUnitAmount(fromMinorUnitAmount minorUnitAmount: NSDecimalNumber) -> NSDecimalNumber {
        return minorUnitAmount.multiplying(byPowerOf10: Int16(-minorUnit))
    }

    func minorUnitAmount(fromMajorUnitAmount majorUnitAmount: NSDecimalNumber) -> NSDecimalNumber {
        return majorUnitAmount.multiplying(byPowerOf10: Int16(minorUnit))
    }
}
