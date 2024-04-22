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
                        let categories = categoryGroup.categories.map { Category(ynabCategory: $0, curency: params.currency) }
                        return (group, categories)
                    }
                let groups = result.map(\.0)
                let categories = result.flatMap(\.1)
                return (groups, categories)
            } catch {
                throw mappedError(error)
            }
        } fetchTransactionsAll: { params in
            do {
                return try await api.transactions
                    .getTransactions(budgetId: params.budgetId, sinceDate: params.startDate)
                    .map { transactionDetail in
                        let categoryGroup = params.categoryGroupProvider?.getCategoryGroupForCategory(id: transactionDetail.categoryId)
                        return Transaction(ynabTransation: transactionDetail, curency: params.currency, categoryGroup: categoryGroup)
                    }
            } catch {
                throw mappedError(error)
            }
        }
    }
}

private extension BudgetProvider {

    static func mappedError(_ error: Error) -> Error {
        if let error = error as? SwiftYNABError {
            return error.mapToBudgetClientError
        }
        return error
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
