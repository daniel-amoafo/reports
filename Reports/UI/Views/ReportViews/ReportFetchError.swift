// Created by Daniel Amoafo on 30/4/2024.

import Foundation

enum ReportFetchError: Error, LocalizedError, Equatable {

    case noResults

    var errorDescription: String? {
        switch self {
        case  .noResults: return  Strings.noResultsMessage
        }
    }
}

private enum Strings {

    static let noResultsMessage = String(
        localized: "No transactions were found for the provided dates",
        comment: "Error message displayed when no results are found for the selected date range."
    )
}
