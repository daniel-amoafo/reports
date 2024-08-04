// Created by Daniel Amoafo on 9/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

// Due to a Swift bug not allowing extensions to be defined on objects that have macro annotations.
// see: https://forums.swift.org/t/macro-circular-reference-error-when-adding-extensions-to-a-type-decorated-by-a-peer-macro/68064/3
enum ReportFeatureSourceLoader {

    static let logger = LogFactory.create(Self.self)

    // Ensure a report is loaded with valid inputField parameters.
    // This is mainly to confirm a SavedReport data can be load and report run
    static func load(_ sourceData: ReportFeature.State.SourceData) throws -> (ReportInputFeature.State, SavedReport?) {

        let inputFeatureState: ReportInputFeature.State
        let savedReport: SavedReport?

        switch sourceData {
        case let .new(state):
            inputFeatureState = state
            savedReport = nil

        case let .existing(id):

            let report = try getReport(id)

            savedReport = report

            let budgetId = report.budgetId

            let chart = try getChart(report)

            let (fromDate, toDate) = try getDates(report)

            let selectedAcountIds = try getAccountIds(report)

            let selectedCategoryIds = try getCategoryIds(report)

            inputFeatureState = .init(
                chart: chart,
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate,
                selectedAccountIds: selectedAcountIds,
                selectedCategoryIds: selectedCategoryIds
            )
        }

        return (inputFeatureState, savedReport)
    }

    private static func getReport(_ id: UUID) throws -> SavedReport {
        @Dependency(\.savedReportQuery) var savedReportQuery
        do {
            return try savedReportQuery.fetchOne(id)
        } catch {
            let msg = "Saved Report could not be loaded from SwiftData. :-/ id: \(id)"
            throw LoadError.reportNotFounded(msg)
        }
    }

    private static func getChart(_ report: SavedReport) throws -> ReportChart {
        guard let chart = ReportChart.defaultCharts[id: report.chartId] else {
            throw LoadError.invalidChartId(
                "\(String(describing: SavedReport.self)) chart id (\(report.chartId)) not found."
            )
        }
        return chart
    }

    private static func getDates(_ report: SavedReport) throws -> (Date, Date) {
        guard let fromDate = Date.iso8601local.date(from: report.fromDate) else {
            logger.error("\(String(describing: SavedReport.self)) fromDate parsing error (\(report.fromDate)).")
            throw LoadError.invalidDateFormat(String(format: Strings.invalidDate, "(\(report.fromDate))."))
        }
        guard let toDate = Date.iso8601local.date(from: report.toDate) else {
            logger.debug("\(String(describing: SavedReport.self)) toDate parsing error (\(report.toDate)).")
            throw LoadError.invalidDateFormat(Strings.invalidDate)
        }

        return (fromDate, toDate)
    }

    private static func getAccountIds(_ report: SavedReport) throws -> String? {
        let accountIdsString = report.selectedAccountIds
        guard accountIdsString.isNotEmpty else { return nil }
        do {
            @Shared(.workspaceValues) var workspaceValues
            let accountNames = workspaceValues.accountsOnBudgetNames
            let accountIds = accountIdsString
                .split(separator: ",")
                .map { String($0) }

            // validate accounts exist
            guard accountIds.allSatisfy({ accountNames.keys.contains($0) }) else {
                logger.error(
                    "\(String(describing: SavedReport.self)) - invalid account id(s) in (\(accountIdsString))."
                )
                throw LoadError.invalidSelectedAccount(Strings.invalidAccount)
            }
            return accountIdsString
        } catch {
            logger.error("\(error.toString())")
            throw LoadError.unknown(Strings.unexpectedError)
        }
    }

    private static func getCategoryIds(_ report: SavedReport) throws -> String? {
        let categoryIdsString = report.selectedCategoryIds
        guard categoryIdsString.isNotEmpty else { return nil }

        // validate categoryIds exists?

        return categoryIdsString
    }

}

extension ReportFeatureSourceLoader {

    enum LoadError: LocalizedError {
        case invalidChartId(String)
        case invalidDateFormat(String)
        case invalidSelectedAccount(String)
        case reportNotFounded(String)
        case unknown(String)

        var errorDescription: String? {
            switch self {
            case let .invalidChartId(message),
                let .invalidDateFormat(message),
                let .invalidSelectedAccount(message),
                let .reportNotFounded(message),
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
