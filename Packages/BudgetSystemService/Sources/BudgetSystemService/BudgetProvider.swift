// Created by Daniel Amoafo on 26/2/2024.

import Foundation
import MoneyCommon

// MARK: - BudgetProvider

public struct BudgetProvider: Sendable {

    let fetchBudgetSummaries: @Sendable () async throws -> [BudgetSummary]
    let fetchCategoryValues: @Sendable (_ params: CategoryGroupParameters) async throws -> ([CategoryGroup], [Category], Int)
    let fetchTransactions: @Sendable (_ params: TransactionParameters) async throws -> [TransactionEntry]
    let fetchAllTransactions: @Sendable (_ params: TransactionParameters) async throws -> ([TransactionEntry], Int)

    public init(
        fetchBudgetSummaries: @Sendable @escaping () async throws -> [BudgetSummary],
        fetchCategoryValues: @Sendable @escaping (_ params: CategoryGroupParameters) async throws -> (groups: [CategoryGroup], categories: [Category], serverKnowledge: Int),
        fetchTransactions: @Sendable @escaping (_ params: TransactionParameters) async throws -> [TransactionEntry],
        fetchAllTransactions: @Sendable @escaping (_ params: TransactionParameters) async throws -> (transactions: [TransactionEntry], serverKnowledge: Int)
    ) {
        self.fetchBudgetSummaries = fetchBudgetSummaries
        self.fetchCategoryValues = fetchCategoryValues
        self.fetchTransactions = fetchTransactions
        self.fetchAllTransactions = fetchAllTransactions
    }

    public struct CategoryGroupParameters: Sendable {
        public let budgetId: String
        public let lastServerKnowledge: Int?
    }

    public struct TransactionParameters: Sendable {
        public enum FilterByOption: Sendable {
            case account(accountId: String)
            case category(categoryId: String)
        }

        public let budgetId: String
        public let startDate: Date?
        public let finishDate: Date?
        public let currency: Currency
        public let filterBy: FilterByOption?
        public let lastServerKnowledge: Int?
    }
}

// MARK: - Static Budget Providers

public extension BudgetProvider {

    /// Static BudgetProvider that does nothing
    static let noop = BudgetProvider(
        fetchBudgetSummaries: { return [] },
        fetchCategoryValues: { _ in return ([], [], 0) },
        fetchTransactions: { _ in return [] },
        fetchAllTransactions: { _ in return ([], 0) }
    )
    
    /// Static BudgetProvider that is not authenticated, throwing an error when any property is invoked.
    static let notAuthorized = BudgetProvider(
        fetchBudgetSummaries: { throw isNotAuthorizedError() },
        fetchCategoryValues: { _ in throw isNotAuthorizedError() },
        fetchTransactions: { _ in throw isNotAuthorizedError() },
        fetchAllTransactions: { _ in throw isNotAuthorizedError() }
    )

    private static func isNotAuthorizedError() -> BudgetClientError {
        .makeIsNotAuthorized()
    }
}
