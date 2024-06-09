// Created by Daniel Amoafo on 8/6/2024.

import Foundation

struct CurrencySymbol {

   /// Returns the currency code. For example USD or EUD
   let code: String

   /// Returns currency symbols. For example ["USD", "US$", "$"] for USD, ["RUB", "₽"] for RUB or ["₴", "UAH"] for UAH
   let symbols: [String]

   /// Returns shortest currency symbols. For example "$" for USD or "₽" for RUB
   var shortestSymbol: String {
      return symbols.min { $0.count < $1.count } ?? ""
   }

   /// Returns information about a currency by its code.
   static func currency(for code: String) -> CurrencySymbol? {
      return cache[code]
   }

   // Global constants and variables are always computed lazily, in a similar manner to Lazy Stored Properties.
   static fileprivate var cache: [String: CurrencySymbol] = { () -> [String: CurrencySymbol] in
      var mapCurrencyCode2Symbols: [String: Set<String>] = [:]
      let currencyCodes = Set(Locale.commonISOCurrencyCodes)

      for localeId in Locale.availableIdentifiers {
         let locale = Locale(identifier: localeId)
          guard let currencyCode = locale.currency?.identifier, let currencySymbol = locale.currencySymbol else {
            continue
         }
         if currencyCode.contains(currencyCode) {
            mapCurrencyCode2Symbols[currencyCode, default: []].insert(currencySymbol)
         }
      }

      var mapCurrencyCode2Currency: [String: CurrencySymbol] = [:]
      for (code, symbols) in mapCurrencyCode2Symbols {
         mapCurrencyCode2Currency[code] = CurrencySymbol(code: code, symbols: Array(symbols))
      }
      return mapCurrencyCode2Currency
   }()
}
