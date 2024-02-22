// Created by Daniel Amoafo on 18/2/2024.

import Foundation

public enum AuthorizationStatus {
    case loggedIn(accessInfo: AccessInfo)
    case logggedOut
    case unknown
}

public struct AccessInfo: Codable, Equatable {
    public let accessToken: String
    public let createdDate: Date
}
