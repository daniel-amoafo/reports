// Created by Daniel Amoafo on 1/5/2024.

import Foundation

class CurrencyFormatter: NumberFormatter {

    init(currency: Currency) {
        super.init()
        self.locale = locale
        self.numberStyle = .currency
        self.currencyCode = currency.code
        self.minimumFractionDigits = currency.minorUnit
        self.maximumFractionDigits = currency.minorUnit
        self.usesGroupingSeparator = true
    }

    override init() {
        fatalError("init(coder:) has not been implemented")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Apple and the internet at large keep reminding formatters are
    // expensive to create especially when initalizing and using in loop logic.
    // This maintains shared instances for Currency Formatter as they canbe used
    private static var formatters: [Currency: CurrencyFormatter] = [:]

    static func forCurrency(currency: Currency) -> CurrencyFormatter {
        if let formatter = formatters[currency] {
            return formatter
        }

        let newFormatter = CurrencyFormatter(currency: currency)
        formatters[currency] = newFormatter
        return newFormatter
    }
}
