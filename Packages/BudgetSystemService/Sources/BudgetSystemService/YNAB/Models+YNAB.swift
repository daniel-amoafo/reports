// Created by Daniel Amoafo on 4/2/2024.

import Foundation
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
    }
}
