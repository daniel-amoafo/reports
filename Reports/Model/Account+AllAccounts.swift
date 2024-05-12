// Created by Daniel Amoafo on 8/5/2024.

import BudgetSystemService
import Foundation

extension Account {

    static var allAccountsId: String { "CW_ALL_ACCOUNTS" }

    static var allAccounts: Account {
        .init(id: allAccountsId, name: AppStrings.allAccountsName, onBudget: true, deleted: false)
    }
}
