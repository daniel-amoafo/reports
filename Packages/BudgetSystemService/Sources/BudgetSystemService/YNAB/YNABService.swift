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
