// Created by Daniel Amoafo on 9/3/2024.

import BudgetSystemService
import IdentifiedCollections
import SwiftUI

struct ReportChart: Identifiable, Equatable, Sendable {
    let type: ChartType
    let name: String
    let description: String

    var id: String { type.id }

    static let defaultCharts: IdentifiedArrayOf<Self> = {
        [
            .init(
                type: .spendingByTotal,
                name: Strings.spendingTotalTitle,
                description: Strings.spendingTotalDescription
            ),
            .init(
                type: .spendingByTrend,
                name: Strings.spendingTrendTitle,
                description: Strings.spendingTrendDescription
            ),
            .init(
                type: .incomeExpensesTable,
                name: Strings.incomeExpenseTitle,
                description: Strings.incomeExpenseDescription
            ),
        ]
    }()

    static var firstChart: Self {
        defaultCharts.elements[0]
    }
}

enum ChartType: Equatable, Sendable {
    case spendingByTotal
    case spendingByTrend
    case incomeExpensesTable
    case line

    var id: String {
        switch self {
        case .spendingByTotal: return "spendingTotal"
        case .spendingByTrend: return "spendingTrend"
        case .incomeExpensesTable: return "incomeVexpense"
        case .line: return "line"
        }
    }

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
            localized: "A pie chart showing spending totals by category for budget accounts.",
            comment: "description text of the spending total chart"
        )
        static let spendingTrendTitle = String(
            localized: "Spending Trend",
            comment: "The title for a chart displaying spending by trend for budget accounts."
        )
        static let spendingTrendDescription = String(
            localized: "A bar chart showing spending trends.",
            comment: "description text of the spending trend chart"
        )
        static let incomeExpenseTitle = String(
            localized: "Income v Expense",
            comment: "The title for a chart displaying income and expenses."
        )
        static let incomeExpenseDescription = String(
            localized: "A table summarising income & expenses for each category in a month",
            comment: "description text of the income expense chart"
        )
    }

}
