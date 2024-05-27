// Created by Daniel Amoafo on 9/5/2024.

import BudgetSystemService
import Dependencies
import Foundation

// Due to a Swift bug not allowing extensions to be defined on objects that have macro annotations.
// see: https://forums.swift.org/t/macro-circular-reference-error-when-adding-extensions-to-a-type-decorated-by-a-peer-macro/68064/3
enum ReportFeatureSourceLoader {

    static let logger = LogFactory.create(category: "\(String(describing: ReportFeatureSourceLoader.self))")

    // Ensure a report is loaded with valid inputField parameters.
    // This is mainly to confirm a SavedReport data can be load and report run
    static func load(_ sourceData: ReportFeature.State.SourceData) throws -> (ReportInputFeature.State, SavedReport?) {

        let inputFeatureState: ReportInputFeature.State
        let savedReport: SavedReport?

        switch sourceData {
        case let .new(state):
            inputFeatureState = state
            savedReport = nil

        case let .existing(report):
            savedReport = report
            guard let chart = ReportChart.defaultCharts[id: report.chartId] else {
                throw LoadError.invalidChartId(
                    "\(String(describing: SavedReport.self)) chart id (\(report.chartId)) not found."
                )
            }
            guard let fromDate = Date.iso8601utc.date(from: report.fromDate) else {
                logger.error("\(String(describing: SavedReport.self)) fromDate parsing error (\(report.fromDate)).")
                throw LoadError.invalidDateFormat(String(format: Strings.invalidDate, "(\(report.fromDate)"))
            }
            guard let toDate = Date.iso8601utc.date(from: report.toDate) else {
                logger.debug("\(String(describing: SavedReport.self)) toDate parsing error (\(report.toDate)).")
                throw LoadError.invalidDateFormat(Strings.invalidDate)
            }

            let selectedAcountId: String?
            do {
                if let accountId = report.selectedAccountId {
                    guard try Account.fetch(id: accountId) != nil else {
                        logger.error("\(String(describing: SavedReport.self)) - invalid account id (\(accountId)).")
                        throw LoadError.invalidSelectedAccount(Strings.invalidAccount)
                    }
                    selectedAcountId = accountId
                } else {
                    selectedAcountId = nil
                }
            } catch {
                logger.error("\(error.toString())")
                throw LoadError.unknown(Strings.unexpectedError)
            }

            inputFeatureState = .init(
                chart: chart,
                fromDate: fromDate,
                toDate: toDate,
                selectedAccountId: selectedAcountId
            )
        }

        return (inputFeatureState, savedReport)
    }

}

extension ReportFeatureSourceLoader {

    enum LoadError: LocalizedError {
        case invalidChartId(String)
        case invalidDateFormat(String)
        case invalidSelectedAccount(String)
        case unknown(String)

        var errorDescription: String? {
            switch self {
            case let .invalidChartId(message),
                let .invalidDateFormat(message),
                let .invalidSelectedAccount(message),
                let .unknown(message):
                return message
            }
        }
    }
}

private enum Strings {

    static let invalidDate = String(
        localized: "A Saved Report date was not valid (%@).",
        comment: "Saved Report date could not be parsed back to a date."
    )

    static let invalidAccount = String(
        localized: "The Saved Report Account could not be found.",
        comment: "Error displayed when the account id wasn't found in database"
    )

    static let unexpectedError =  String(
        localized: "Opps, there was an unexpected error loading the saved report.",
        comment: "A generic error message displauyed when unable to load a saved report for an unknown reason"
    )

}
