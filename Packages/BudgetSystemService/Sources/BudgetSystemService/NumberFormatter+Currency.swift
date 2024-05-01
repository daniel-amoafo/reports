// Created by Daniel Amoafo on 1/5/2024.

import Foundation
import MoneyCommon

extension NumberFormatter {

    static func formatter(for currency: Currency) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.minimumFractionDigits = currency.minorUnit
        formatter.maximumFractionDigits = currency.minorUnit
        return formatter
    }

}
