// Created by Daniel Amoafo on 4/2/2024.

import Foundation
import SwiftYNAB


public extension BudgetProvider {

    static func ynab(accessToken: String) -> Self {
        let api = YNAB(accessToken: accessToken)
        return .init {
            do {
                return try await api.budgets.getBudgets().map(BudgetSummary.init)
            } catch {
                throw mappedError(error)
            }

        } fetchAccounts: { budgetId in
            do {
                return try await api.accounts.getAccounts(budgetId: budgetId).map(Account.init)
            } catch {
                throw mappedError(error)
            }
        } fetchCategoryValues: { params in
            do {
                let result = try await api.categories.getCategories(budgetId: params.budgetId)
                    .map { categoryGroup -> (CategoryGroup, [Category]) in
                        let group = CategoryGroup(ynabCategoryGroup: categoryGroup)
                        let categories = categoryGroup.categories.map { Category(ynabCategory: $0, currency: params.currency) }
                        return (group, categories)
                    }
                let groups = result.map(\.0)
                let categories = result.flatMap(\.1)
                return (groups, categories)
            } catch {
                throw mappedError(error)
            }
        } fetchTransactions: { params in
            do {
                if let filterBy = params.filterBy {
                    switch filterBy {
                    case let .account(accountId):
                        return try await fetchTransactionDetails(params: params, api: api, accountId: accountId)
                    case let .category(categoryId) :
                        return try await fetchTransactionHybrids(params: params, api: api, type: .category(id: categoryId))
                    }
                }  else {
                    return try await fetchTransactionDetails(params: params, api: api, accountId: nil)
                }
            } catch {
                throw mappedError(error)
            }
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
                .getTransactions(budgetId: params.budgetId, accountId: accountId, sinceDate: params.startDate)
        } else {
            transactionDetails = try await api.transactions
                .getTransactions(budgetId: params.budgetId, sinceDate: params.startDate)
        }

        return transactionDetails
            .map {
                let categoryGroup = params.categoryGroupProvider?.getCategoryGroupForCategory(id: $0.categoryId)
                return TransactionEntry(ynabTransactionDetail: $0, currency: params.currency, categoryGroup: categoryGroup)
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
                let categoryGroup = params.categoryGroupProvider?.getCategoryGroupForCategory(id: $0.categoryId)
                return TransactionEntry(ynabHybridTransaction: $0, currency: params.currency, categoryGroup: categoryGroup)
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
