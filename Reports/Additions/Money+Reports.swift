// Created by Daniel Amoafo on 15/8/2024.

import MoneyCommon

extension Money {

    var reportsFormatted: String {
        amountFormatted(formatter: .reportsStandard, for: .current)
    }
}

extension MoneyFormatter {

    /// Typical display of dollars and cents, e.g. "$25.00" or "¥1,000"
    static let reportsStandard = MoneyFormatter(
        options: Options(
            numberFormat: .localized,
            currencyRepresentationOption: .symbol,
            denominationOption: .dollar(
                omitsCentsIfPossible: false,
                reduceCentsToMinimumSignificantDigits: false,
                showsAsCentsIfPossible: false
            ),
            signOption: .none,
            zeroBiasOption: .none
        )
    )
}
