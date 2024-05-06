// Created by Daniel Amoafo on 5/5/2024.

import Foundation
import SwiftData

@Model
final class SavedReport: Identifiable {

    @Attribute(.unique) let id: UUID
    let name: String
    let fromDate: String
    let toDate: String
    let chartId: String
    let selectedAccountId: String?
    let lastModifield: Date

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
