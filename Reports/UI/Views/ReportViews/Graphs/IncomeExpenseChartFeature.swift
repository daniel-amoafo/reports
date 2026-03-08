// Created by Daniel Amoafo on 3/3/2026.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import MoneyCommon

@Reducer
struct IncomeExpenseChartFeature {

    @ObservableState
    struct State: Equatable {
        let title: String
        let budgetId: String
        let fromDate: Date
        let toDate: Date
        let accountIds: String?
        let categoryIds: String?

        var chartType: ChartToggleType = .bar
        var reportData: IncomeExpenseReportData?

        @Shared(.workspaceValues) var workspaceValues

        enum ChartToggleType: String, CaseIterable, Identifiable {
            case bar, line
            var id: String { self.rawValue }
        }

        init(
            title: String,
            budgetId: String,
            fromDate: Date,
            toDate: Date,
            accountIds: String?,
            categoryIds: String?
        ) {
            self.title = title
            self.budgetId = budgetId
            self.fromDate = fromDate
            self.toDate = toDate
            self.accountIds = accountIds
            self.categoryIds = categoryIds

            // Initial data fetch could happen here or in onAppear
        }

        var hasResults: Bool {
            reportData != nil
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case reportDataResponse(IncomeExpenseReportData)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.database.grdb) var grdb

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                let budgetId = state.budgetId
                let fromDate = state.fromDate
                let toDate = state.toDate
                let accountIds = state.accountIds
                let categoryIds = state.categoryIds

                return .run { send in
                    let data = IncomeExpenseQueries.fetchReportData(
                        budgetId: budgetId,
                        fromDate: fromDate,
                        toDate: toDate,
                        accountIds: accountIds,
                        categoryIds: categoryIds,
                        grdb: grdb
                    )
                    await send(.reportDataResponse(data))
                }

            case let .reportDataResponse(data):
                state.reportData = data
                return .none

            case .binding:
                return .none
            }
        }
    }
}

struct IncomeExpenseReportData: Equatable, Sendable {
    let incomeTrends: [TrendRecord]
    let expenseTrends: [TrendRecord]
    let totalIncome: Money
    let totalExpenses: Money
    let netBalance: Money
    let incomePercentageChange: Double?
    let expensePercentageChange: Double?
}

// MARK: - Queries

enum IncomeExpenseQueries {
    static let logger = LogFactory.create(Self.self)

    static func fetchReportData(
        budgetId: String,
        fromDate: Date,
        toDate: Date,
        accountIds: String?,
        categoryIds: String?,
        grdb: GRDBDatabase
    ) -> IncomeExpenseReportData {
        IncomeExpenseReportQueries.fetchReportData(
            budgetId: budgetId,
            fromDate: fromDate,
            toDate: toDate,
            accountIds: accountIds,
            categoryIds: categoryIds,
            grdb: grdb
        )
    }
}
