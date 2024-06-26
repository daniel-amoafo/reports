// Created by Daniel Amoafo on 4/2/2024.

import Foundation
import SwiftYNAB


public extension BudgetProvider {

    static func ynab(accessToken: String) -> Self {
        let api = YNAB(accessToken: accessToken)
        return .init {
            do {
                return try await api.budgets.getBudgets(includeAccounts: true).map(BudgetSummary.init)
            } catch {
                throw mappedError(error)
            }

        } fetchCategoryValues: { params in
            do {
                let (categoryGroupsWithCategories, serverKnowledge) = try await api.categories.getCategories(
                    budgetId: params.budgetId, lastKnowledgeOfServer: params.lastServerKnowledge
                )
                let result = categoryGroupsWithCategories
                    .map { categoryGroup -> (CategoryGroup, [Category]) in
                        let group = CategoryGroup(
                            ynabCategoryGroup: categoryGroup,
                            budgetId: params.budgetId
                        )
                        let categories = categoryGroup.categories.map {
                            Category(ynabCategory: $0, budgetId: params.budgetId)
                        }
                        return (group, categories)
                    }
                let groups = result.map(\.0)
                let categories = result.flatMap(\.1)
                return (groups, categories, serverKnowledge)
            } catch {
                throw mappedError(error)
            }
        } fetchTransactions: { params in
            do {
                if let filterBy = params.filterBy {
                    switch filterBy {
                    case let .account(accountId):
                        return try await fetchTransactionDetails(params: params, api: api, accountId: accountId)
                    case let .category(categoryId):
                        return try await fetchTransactionHybrids(params: params, api: api, type: .category(id: categoryId))
                    }
                }  else {
                    return try await fetchTransactionDetails(params: params, api: api, accountId: nil)
                }
            } catch {
                throw mappedError(error)
            }
        } fetchAllTransactions: { params in
            let (details, serverKnowledge) = try await api.transactions
                .getTransactionsWithServerKnowledge(
                    budgetId: params.budgetId,
                    sinceDate: nil,
                    type: nil,
                    lastKnowledgeOfServer: params.lastServerKnowledge
                )
            let transactions = details.map {
                return TransactionEntry(
                    ynabTransactionDetail: $0,
                    budgetId: params.budgetId,
                    currency: params.currency
                )
            }
            return (transactions, serverKnowledge)
        }
    }
}

private extension BudgetProvider {

    enum TransactionHistoryType {
        case category(id: String)
        case payee(id: String)
    }

    static func mappedError(_ error: Error) -> Error {
        if let error = error as? SwiftYNABError {
            return error.mapToBudgetClientError
        }
        return error
    }

    static func fetchTransactionDetails(params: TransactionParameters, api: YNAB, accountId: String?) async throws -> [TransactionEntry] {
        let transactionDetails: [TransactionDetail]
        if let accountId {
            transactionDetails = try await api.transactions
                .getTransactions(
                    budgetId: params.budgetId,
                    accountId: accountId,
                    sinceDate: params.startDate
                )
        } else {
            transactionDetails = try await api.transactions
                .getTransactions(budgetId: params.budgetId, sinceDate: params.startDate)
        }

        return transactionDetails
            .map {
                TransactionEntry(
                    ynabTransactionDetail: $0,
                    budgetId: params.budgetId,
                    currency: params.currency
                )
            }
    }

    static func fetchTransactionHybrids(params: TransactionParameters, api: YNAB, type: TransactionHistoryType) async throws -> [TransactionEntry] {
        let hybridTransactions: [HybridTransaction]
        switch type {
        case let .category(categoryId) :
            hybridTransactions = try await api.transactions.getTransactions(budgetId: params.budgetId, categoryId: categoryId, sinceDate: params.startDate)
        case .payee:
            fatalError("fetch transaction by payee not implemented yet :-/")
        }

        return hybridTransactions
            .map {
                TransactionEntry(
                    ynabHybridTransaction: $0,
                    budgetId: params.budgetId,
                    currency: params.currency
                )
            }
    }
}

private extension SwiftYNABError {

    var mapToBudgetClientError: BudgetClientError {
        switch self {
        case let .apiError(errorDetail):
            return .http(code: errorDetail.id, message: "\(errorDetail.name) - \(errorDetail.detail)")

        case let .httpError(statusCode):
            return .http(code: "\(statusCode)", message: nil)

        case .unknown, .decodingFailure, .encodingFailure:
            return .unknown
        }
    }
}
