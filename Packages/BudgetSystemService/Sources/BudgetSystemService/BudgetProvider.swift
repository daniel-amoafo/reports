// Created by Daniel Amoafo on 26/2/2024.

import Foundation
import MoneyCommon

// MARK: - BudgetProvider

public struct BudgetProvider {

    let fetchBudgetSummaries: () async throws -> [BudgetSummary]
    let fetchAccounts: (_ budgetId: String) async throws -> [Account]
    let fetchCategoryValues: (_ params: CategoryGroupParameters) async throws -> (groups: [CategoryGroup], categories: [Category])
    let fetchTransactionsAll: (_ params: TransactionParameters) async throws -> [Transaction]

    public init(
        fetchBudgetSummaries: @Sendable @escaping () async throws -> [BudgetSummary],
        fetchAccounts: @Sendable @escaping (_ budgetId: String) async throws -> [Account],
        fetchCategoryValues: @Sendable @escaping (_ params: CategoryGroupParameters) async throws -> (groups: [CategoryGroup], categories: [Category]),
        fetchTransactionsAll: @Sendable @escaping (_ params: TransactionParameters) async throws -> [Transaction]
//      fetchTransactionsByAccount
//      fetchTransactionsByCategory
    ) {
        self.fetchBudgetSummaries = fetchBudgetSummaries
        self.fetchAccounts = fetchAccounts
        self.fetchCategoryValues = fetchCategoryValues
        self.fetchTransactionsAll = fetchTransactionsAll
    }

    public struct CategoryGroupParameters {
        public let budgetId: String
        public let currency: Currency
    }

    public struct TransactionParameters {
        public let budgetId: String
        public let startDate: Date
        public let finishDate: Date
        public let currency: Currency
        public let categoryGroupProvider: CategoryGroupLookupProviding?
    }
}

// MARK: - Static Budget Providers

public extension BudgetProvider {

    /// Static BudgetProvider that does nothing
    static let noop = BudgetProvider(
        fetchBudgetSummaries: { return [] },
        fetchAccounts: { _ in return [] }, 
        fetchCategoryValues: { _ in return ([],[]) },
        fetchTransactionsAll: { _ in return [] }
    )

    /// A variant of the client that is not authenticated throwing an error when any property is invoked.
    static let notAuthorized = BudgetProvider(
        fetchBudgetSummaries: { throw isNotAuthorizedError() },
        fetchAccounts: { _ in throw isNotAuthorizedError() },
        fetchCategoryValues: { _ in throw isNotAuthorizedError() },
        fetchTransactionsAll: { _ in throw isNotAuthorizedError() }
    )

    private static func isNotAuthorizedError() -> BudgetClientError {
        BudgetClientError.makeIsNotAuthorized()
    }
}
