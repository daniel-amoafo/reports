// Created by Daniel Amoafo on 4/2/2024.

import Foundation
import SwiftYNAB


public extension BudgetProvider {

    static func ynab(accessToken: String) -> Self {
        let api = YNAB(accessToken: accessToken)
        return .init { budgetId in
            try await api.accounts.getAccounts(budgetId: budgetId).map(Account.init)
        }
    }

}
