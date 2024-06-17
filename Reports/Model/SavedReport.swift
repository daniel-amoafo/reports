// Created by Daniel Amoafo on 5/5/2024.

import Foundation
import SwiftData

@Model
final class SavedReport: Identifiable, Equatable {

    @Attribute(.unique) let id: UUID
    var name: String
    var fromDate: String
    var toDate: String
    var chartId: String
    var budgetId: String
    var selectedAccountIds: String
    var lastModifield: Date

    init(
        id: UUID = UUID(),
        name: String,
        fromDate: String,
        toDate: String,
        chartId: String,
        budgetId: String,
        selectedAccountIds: String,
        lastModified: Date
    ) {
        self.id = id
        self.name = name
        self.fromDate = fromDate
        self.toDate = toDate
        self.chartId = chartId
        self.budgetId = budgetId
        self.selectedAccountIds = selectedAccountIds
        self.lastModifield = lastModified
    }
}

extension SavedReport: CustomDebugStringConvertible {

    var debugDescription: String {
        "name: \(name), fromDate: \(fromDate), toDate: \(toDate), " +
        "budgetId: \(budgetId)" +
        "selectedAccountIds: \(selectedAccountIds), chartId: \(chartId)"
    }

}

// MARK: -

/// A lightweight immuatable, Sendable version of a SavedReport.
/// Contains only required fields for displaying content to screen.
struct DisplaySavedReport: Identifiable, Equatable, Sendable {

    let id: UUID
    let name: String
    let chartId: String

    init(_ report: SavedReport) {
        self.id = report.id
        self.name = report.name
        self.chartId = report.chartId
    }
}
