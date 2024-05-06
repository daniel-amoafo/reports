// Created by Daniel Amoafo on 9/3/2024.

import IdentifiedCollections
import SwiftUI

struct ReportChart: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let type: ChartType

    static let defaultCharts: IdentifiedArrayOf<Self> = {
        [
            .init(
                id: "spendingTotal",
                name: Strings.spendingTotalTitle,
                description: Strings.spendingTotalDescription,
                type: .spendingByTotal
            ),
            .init(
                id: "spendingTrend",
                name: Strings.spendingTrendTitle,
                description: Strings.spendingTrendDescription,
                type: .spendingByTrend
            ),
            .init(
                id: "incomeVexpense",
                name: Strings.incomeExpenseTitle,
                description: Strings.incomeExpenseDescription,
                type: .incomeExpensesTable
            ),
        ]
    }()

    static var firstChart: Self {
        defaultCharts.elements[0]
    }
}

enum ChartType: Equatable {
    case spendingByTotal
    case spendingByTrend
    case incomeExpensesTable
    case line

    var image: Image {
        switch self {
        case .spendingByTrend:
            return Image(.chartBar)
        case .line:
            return Image(.chartLine)
        case .spendingByTotal:
            return Image(.chartPie)
        case .incomeExpensesTable:
            return Image(.chartTable)
        }
    }
}

extension ReportChart {

    private enum Strings {
        static let spendingTotalTitle = String(
            localized: "Spending Total",
            comment: "The title for a chart displaying spending totals by category"
        )
        static let spendingTotalDescription = String(
            localized: "A pie chart showing spending totals by category",
            comment: "description text of the spending total chart"
        )
        static let spendingTrendTitle = String(
            localized: "Spending Trend",
            comment: "The title for a chart displaying spending by trend"
        )
        static let spendingTrendDescription = String(
            localized: "A bar chart showing spending trends",
            comment: "description text of the spending trend chart"
        )
        static let incomeExpenseTitle = String(
            localized: "Income v Expense",
            comment: "The title for a chart displaying income and expenses"
        )
        static let incomeExpenseDescription = String(
            localized: "A table summarising income & expenses for each category in a month",
            comment: "description text of the income expense chart"
        )
    }

}
