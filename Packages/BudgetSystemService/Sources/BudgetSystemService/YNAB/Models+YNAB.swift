// Created by Daniel Amoafo on 4/2/2024.

import Foundation
import MoneyCommon
import SwiftYNAB

extension Account {
    
    init(ynabAccount: SwiftYNAB.Account) {
        self.id = ynabAccount.id
        self.name = ynabAccount.name
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

    init(ynabCategory: SwiftYNAB.Category, curency: Currency) {
        self.id = ynabCategory.id
        self.name = ynabCategory.name
        self.categoryGroupId = ynabCategory.categoryGroupId
        self.hidden = ynabCategory.hidden
        self.note = ynabCategory.note
        self.deleted = ynabCategory.deleted
        self.balance = Money.forYNAB(amount: ynabCategory.balance, currency: curency)
    }
}

extension Transaction {

    init(ynabTransation: SwiftYNAB.TransactionDetail, curency: Currency, categoryGroup: CategoryGroup?) {
        self.id = ynabTransation.id
        self.accountId = ynabTransation.accountId
        self.accountName = ynabTransation.accountName
        self.categoryId = ynabTransation.categoryId
        self.categoryName = ynabTransation.categoryName
        self.categoryGroupId = categoryGroup?.id
        self.categoryGroupName = categoryGroup?.name
        self.transferAccountId = ynabTransation.transferAccountId
        self.money = Money.forYNAB(amount: ynabTransation.amount, currency: curency)
        self.deleted = ynabTransation.deleted

        guard let date = DateConverter.date(from: ynabTransation.date) else {
            fatalError("Unable to convert ynab transaction date string into a Date instance - \(ynabTransation.date)")
        }
        self.date = date
    }
}

extension Money {

    static func forYNAB(amount: Int, currency: Currency) -> Self {
        // YNAB amounts store values unit milli units to the thousandths. see https://api.ynab.com/#formats
        .init(.init(amount / 1_000), currency: currency)
    }
}
