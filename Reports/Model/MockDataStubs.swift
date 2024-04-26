// Created by Daniel Amoafo on 23/4/2024.

import BudgetSystemService
import Foundation
import IdentifiedCollections

extension ReportChart {

    static let mock: ReportChart = Self.makeDefaultCharts()[0]
}

extension IdentifiedArray where ID == Account.ID, Element == Account {

    static let mocks: Self = [
        .init(id: "01", name: "Everyday Account", deleted: false),
        .init(id: "02", name: "Acme Account", deleted: false),
        .init(id: "03", name: "Appleseed Account", deleted: false),
    ]
}
