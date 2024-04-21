// Created by Daniel Amoafo on 4/2/2024.

import Foundation
import MoneyCommon
import SwiftYNAB

extension Account {
    
    init(ynabAccount: SwiftYNAB.Account) {
        self.id = ynabAccount.id
        self.name = ynabAccount.name
    }
}

extension BudgetSummary {
    
    init(ynabBudgetSummary: SwiftYNAB.BudgetSummary) {
        self.id = ynabBudgetSummary.id
        self.name = ynabBudgetSummary.name
        self.lastModifiedOn = ynabBudgetSummary.lastModifiedOn
        self.firstMonth = ynabBudgetSummary.firstMonth
        self.lastMonth = ynabBudgetSummary.lastMonth
        
        guard let currency = Currency.iso4217Currency(for: ynabBudgetSummary.currencyFormat.isoCode) else {
            fatalError("Expected Currency not found using isoCode - \(ynabBudgetSummary.currencyFormat.isoCode)")
        }
        self.currency = currency
    }
}

extension Transaction {

    init(ynabTransation: SwiftYNAB.TransactionDetail, curency: Currency) {
        self.id = ynabTransation.id
        self.accountId = ynabTransation.accountId
        self.accountName = ynabTransation.accountName
        self.categoryId = ynabTransation.categoryId
        self.categoryName = ynabTransation.categoryName
        self.money = Money(.init(ynabTransation.amount), currency: curency)

        guard let date = DateConverter.date(from: ynabTransation.date) else {
            fatalError("Unable to convert ynab transaction date string into a Date instance - \(ynabTransation.date)")
        }
        self.date = date
    }
}
