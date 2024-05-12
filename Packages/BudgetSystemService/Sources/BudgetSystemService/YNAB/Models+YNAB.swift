// Created by Daniel Amoafo on 4/2/2024.

import Foundation
import MoneyCommon
import SwiftYNAB

extension Account {
    
    init(ynabAccount: SwiftYNAB.Account) {
        self.id = ynabAccount.id
        self.name = ynabAccount.name
        self.onBudget = ynabAccount.onBudget
        self.deleted = ynabAccount.deleted
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

extension CategoryGroup {

    init(ynabCategoryGroup: SwiftYNAB.CategoryGroupWithCategories) {
        self.id = ynabCategoryGroup.id
        self.name = ynabCategoryGroup.name
        self.hidden = ynabCategoryGroup.hidden
        self.deleted = ynabCategoryGroup.deleted
        self.categoryIds = ynabCategoryGroup.categories.map(\.id)
    }
}

extension Category {

    init(ynabCategory: SwiftYNAB.Category, currency: Currency) {
        self.id = ynabCategory.id
        self.name = ynabCategory.name
        self.categoryGroupId = ynabCategory.categoryGroupId
        self.hidden = ynabCategory.hidden
        self.note = ynabCategory.note
        self.deleted = ynabCategory.deleted
        self.balance = Money.forYNAB(amount: ynabCategory.balance, currency: currency)
    }
}

extension TransactionEntry {

    init(ynabTransactionDetail ynab: SwiftYNAB.TransactionDetail, currency: Currency, categoryGroup: CategoryGroup?) {
        self.id = ynab.id
        self.payeeName = ynab.payeeName
        self.accountId = ynab.accountId
        self.accountName = ynab.accountName
        self.categoryId = ynab.categoryId
        self.categoryName = ynab.categoryName
        self.categoryGroupId = categoryGroup?.id
        self.categoryGroupName = categoryGroup?.name
        self.transferAccountId = ynab.transferAccountId
        self.money = Money.forYNAB(amount: ynab.amount, currency: currency)
        self.deleted = ynab.deleted

        guard let date = DateConverter.date(from: ynab.date) else {
            fatalError("Unable to convert ynab transaction date string into a Date instance - \(ynab.date)")
        }
        self.date = date
    }

    init(ynabHybridTransaction ynab: HybridTransaction, currency: Currency, categoryGroup: CategoryGroup?) {
        self.id = ynab.id
        self.payeeName = ynab.payeeName
        self.accountId = ynab.accountId
        self.accountName = ynab.accountName
        self.categoryId = ynab.categoryId
        self.categoryName = ynab.categoryName
        self.categoryGroupId = categoryGroup?.id
        self.categoryGroupName = categoryGroup?.name
        self.transferAccountId = ynab.transferAccountId
        self.money = Money.forYNAB(amount: ynab.amount, currency: currency)
        self.deleted = ynab.deleted

        guard let date = DateConverter.date(from: ynab.date) else {
            fatalError("Unable to convert ynab transaction date string into a Date instance - \(ynab.date)")
        }
        self.date = date
    }
}

extension Money {

    static func forYNAB(amount: Int, currency: Currency) -> Self {
        // YNAB amounts store values in milli units (to the thousandths). see https://api.ynab.com/#formats
        let ynabMilliUnits: Double = 1_000
        let amountConverted = Decimal(Double(amount) / ynabMilliUnits)
        let amountInCurrencyMilliUnits = (amountConverted as NSDecimalNumber)
            .multiplying(byPowerOf10: Int16(currency.minorUnit), withBehavior: roundingBehavior) as Decimal
        
        return .init(amountInCurrencyMilliUnits, currency: currency)
    }

    private static var roundingBehavior: NSDecimalNumberHandler {
        .init(
           roundingMode: .plain,
           scale: 0, // scale is set to 0 to prevent rounding (i.e. exact precision)
           raiseOnExactness: false,
           raiseOnOverflow: false,
           raiseOnUnderflow: false,
           raiseOnDivideByZero: false
       )
    }
}
