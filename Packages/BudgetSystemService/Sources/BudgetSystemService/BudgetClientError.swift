// Created by Daniel Amoafo on 8/3/2024.

import Foundation

// MARK: - BudgetClientError

public enum BudgetClientError: LocalizedError {

    case http(code: String, message: String?)
    case selectedBudgetIdInvalid
    case unknown

    private enum Strings {
        static let selectedBudgetError = String(
            localized: "The selected budget is not valid or could not be found.",
            comment: "The selected budget id is not available for selection"
        )
    }

    public var errorDescription: String? {
        switch self {
        case let .http(_, message):
            return message
        case .selectedBudgetIdInvalid:
            return Strings.selectedBudgetError
        case .unknown:
            return nil
        }
    }

    public var code: String? {
        switch self {
        case let .http(code, _):
            return code
        case .unknown, .selectedBudgetIdInvalid:
            return nil
        }
    }

    var isNotAuthorized: Bool {
        if let code = self.code, code == "401" {
            return true
        }
        return false
    }

    static func makeIsNotAuthorized() -> Self {
        .http(code: "401", message: "client not authenticated")
    }
}
