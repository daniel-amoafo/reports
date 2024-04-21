// Created by Daniel Amoafo on 26/2/2024.

import Foundation
import MoneyCommon

// MARK: - BudgetProvider

public struct BudgetProvider {

    private let _fetchBudgetSummaries: () async throws -> [BudgetSummary]
    private let _fetchAccounts: (_ budgetId: String) async throws -> [Account]
    let fetchTransactionsAll: (_ budgetId: String, _ startDate: Date, _ currency: Currency) async throws -> [Transaction]

    public init(
        fetchBudgetSummaries: @Sendable @escaping () async throws -> [BudgetSummary],
        fetchAccounts: @Sendable @escaping (_ budgetId: String) async throws -> [Account],
        fetchTransactionsAll: @Sendable @escaping (_ budgetId: String, _ startDate: Date, _ currency: Currency) async throws -> [Transaction]
//      fetchTransactionsByAccount
//      fetchTransactionsByCategory
    ) {
        self._fetchBudgetSummaries = fetchBudgetSummaries
        self._fetchAccounts = fetchAccounts
        self.fetchTransactionsAll = fetchTransactionsAll
    }

}

public extension BudgetProvider {

    func fetchBudgetSummaries() async throws -> [BudgetSummary] {
        try await _fetchBudgetSummaries()
    }

    func fetchAccounts(for budgetId: String) async throws -> [Account] {
        try await _fetchAccounts(budgetId)
    }

}

public extension BudgetProvider {

    // Static BudgetProvider that does nothing
    static let noop = BudgetProvider(
        fetchBudgetSummaries: { return [] },
        fetchAccounts: { _ in return [] }, 
        fetchTransactionsAll: { _,_,_  in return [] }
    )

    //
    static let notAuthorized = BudgetProvider(
        fetchBudgetSummaries: { throw isNotAuthorizedError() },
        fetchAccounts: { _ in throw isNotAuthorizedError()  },
        fetchTransactionsAll: { _,_,_ in throw isNotAuthorizedError() }
    )

    private static func isNotAuthorizedError() -> BudgetClientError {
        BudgetClientError.makeIsNotAuthorized()
    }
}
