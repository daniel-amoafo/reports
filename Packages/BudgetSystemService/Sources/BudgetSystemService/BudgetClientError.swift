// Created by Daniel Amoafo on 8/3/2024.

import Foundation

// MARK: - BudgetClientError

public enum BudgetClientError: LocalizedError {

    case http(code: String, message: String?)
    case unknown

    public var errorDescription: String? {
        switch self {
        case let .http(_, message):
            return message
        case .unknown:
            return nil
        }
    }

    public var code: String? {
        switch self {
        case let .http(code, _):
            return code
        case .unknown:
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
