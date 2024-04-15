// Created by Daniel Amoafo on 9/3/2024.

import SwiftUI

struct Chart: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let type: ChartType
}

enum ChartType: Equatable {
    case bar
    case pie
    case line
    case table

    var image: Image {
        switch self {
        case .bar:
            return Image(R.image.chartBar)
        case .line:
            return Image(R.image.chartLine)
        case .pie:
            return Image(R.image.chartPie)
        case .table:
            return Image(R.image.chartTable)
        }
    }
}

extension Chart {

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

    static func makeDefaultCharts() -> [Chart] {
        [
            .init(
                id: "spendingTotal",
                name: Strings.spendingTotalTitle,
                description: Strings.spendingTotalDescription,
                type: .pie
            ),
            .init(
                id: "spendingTrend",
                name: Strings.spendingTrendTitle,
                description: Strings.spendingTrendDescription,
                type: .bar
            ),
            .init(
                id: "incomeVexpense",
                name: Strings.incomeExpenseTitle,
                description: Strings.incomeExpenseDescription,
                type: .table
            ),
        ]
    }

}
