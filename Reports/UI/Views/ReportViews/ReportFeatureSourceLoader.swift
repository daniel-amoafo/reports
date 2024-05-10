// Created by Daniel Amoafo on 9/5/2024.

import Dependencies
import Foundation

// Due to a Swift bug not allowing extensions to be defined on objects that have macro annotations.
// see: https://forums.swift.org/t/macro-circular-reference-error-when-adding-extensions-to-a-type-decorated-by-a-peer-macro/68064/3
enum ReportFeatureSourceLoader {

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
            guard let fromDate = Date.iso8601Formatter.date(from: report.fromDate) else {
                throw LoadError.invalidDateFormat(
                    "\(String(describing: SavedReport.self)) fromDate could not be parsed (\(report.fromDate))."
                )
            }
            guard let toDate = Date.iso8601Formatter.date(from: report.toDate) else {
                throw LoadError.invalidDateFormat(
                    "\(String(describing: SavedReport.self)) toDate could not be parsed (\(report.toDate))."
                )
            }

            let selectedAcountId: String?
            if let accountId = report.selectedAccountId {
                @Dependency(\.budgetClient) var budgetClient
                guard budgetClient.accounts[id: accountId] != nil else {
                    throw LoadError.invalidSelectedAccount(
                        "\(String(describing: SavedReport.self)) invalid account id (\(accountId))."
                    )
                }
                selectedAcountId = accountId
            } else {
                selectedAcountId = nil
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

        var errorDescription: String? {
            switch self {
            case let .invalidChartId(message),
                let .invalidDateFormat(message),
                let .invalidSelectedAccount(message):
                return message
            }
        }
    }
}
