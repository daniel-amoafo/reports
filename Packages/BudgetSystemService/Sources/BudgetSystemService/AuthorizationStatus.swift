// Created by Daniel Amoafo on 18/2/2024.

import Foundation

public enum AuthorizationStatus: Equatable {
    case loggedIn
    case loggedOut
    case unknown
}

extension AuthorizationStatus: CustomStringConvertible {

    public var description: String {
        switch self {
        case .loggedIn:
            return "loggedIn"
        case .loggedOut:
            return "loggedOut"
        case .unknown:
            return "unknown"
        }
    }
}
