// Created by Daniel Amoafo on 26/2/2024.

import Foundation

// MARK: - BudgetProvider

public struct BudgetProvider {

    private let _fetchBudgetSummaries: () async throws -> [BudgetSummary]
    private let _fetchAccounts: (_ budgetId: String) async throws -> [Account]

    public init(
        fetchBudgetSummaries: @Sendable @escaping () async throws -> [BudgetSummary],
        fetchAccounts: @Sendable @escaping (_ budgetId: String) async throws -> [Account]
    ) {
        self._fetchBudgetSummaries = fetchBudgetSummaries
        self._fetchAccounts = fetchAccounts
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

extension BudgetProvider {

    // Static BudgetProvider that does nothing
    static let noop = BudgetProvider(
        fetchBudgetSummaries: { return [] },
        fetchAccounts: { _ in return [] }
    )
}
