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
    var selectedAccountId: String?
    var lastModifield: Date

    init(
        id: UUID = UUID(),
        name: String,
        fromDate: String,
        toDate: String,
        chartId: String,
        selectedAccountId: String? = nil,
        lastModified: Date
    ) {
        self.id = id
        self.name = name
        self.fromDate = fromDate
        self.toDate = toDate
        self.chartId = chartId
        self.selectedAccountId = selectedAccountId
        self.lastModifield = lastModified
    }
}
