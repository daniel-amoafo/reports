// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct ReportInputFeature {

    @ObservableState
    struct State: Equatable {
        let chart: ReportChart
        let budgetId: String
        var showChartMoreInfo = false
        var fromDate: Date
        var toDate: Date
        @Shared(.wsValues) var workspaceValues
        @Presents var selectedAccounts: SelectAccountsFeature.State?
        var popoverFromDate = false
        var popoverToDate = false

        init(
            chart: ReportChart,
            budgetId: String,
            fromDate: Date = Date.firstDayOfLastMonth,
            toDate: Date = Date.lastDayOfThisMonth,
            selectedAccountIds: String? = nil
        ) {
            self.chart = chart
            self.budgetId = budgetId
            self.fromDate = fromDate
            self.toDate = toDate
            self.workspaceValues.updateSelecteAccountIds(ids: selectedAccountIds)
        }

        var selectedAccountIds: String? {
            workspaceValues.selectedAccountIds
        }

        var selectedAccountIdsSet: Set<String> {
            workspaceValues.selectedAccountIdsSet
        }

        var selectedAccountNames: String? {
            workspaceValues.selectedAccountOnBudgetIdNames
        }

        var isAccountSelected: Bool {
            selectedAccountIds != nil
        }
        var isRunReportDisabled: Bool {
            !isAccountSelected
        }

        var fromDateFormatted: String { Date.iso8601local.string(from: fromDate) }
        var toDateFormatted: String { Date.iso8601local.string(from: toDate) }

        func isEqual(to savedReport: SavedReport) -> Bool {
            func accountIdsAreEqual(_ lhs: String, _ rhs: String) -> Bool {
                if lhs == rhs {
                    return true
                }
                let lhsSet = workspaceValues.makeSet(for: lhs)
                let rhsSet = workspaceValues.makeSet(for: rhs)
                return lhsSet == rhsSet
            }
            return savedReport.fromDate == fromDateFormatted &&
            savedReport.toDate == toDateFormatted &&
            accountIdsAreEqual(savedReport.selectedAccountIds, selectedAccountIds ?? "")
        }
    }

    enum Action {
        case chartMoreInfoTapped
        case delegate(Delegate)
        case selectAccounts(PresentationAction<SelectAccountsFeature.Action>)
        case updateFromDateTapped(Date)
        case updateToDateTapped(Date)
        case setPopoverFromDate(Bool)
        case setPopoverToDate(Bool)
        case selectAccountRowTapped
        case runReportTapped
        case onAppear

        @CasePathable
        enum Delegate: Equatable {
            case reportReadyToRun
        }

    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.configProvider) var configProvider

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .chartMoreInfoTapped:
                state.showChartMoreInfo = !state.showChartMoreInfo
                return .none

            case let .setPopoverFromDate(isPresented):
                state.popoverFromDate = isPresented
                return .none

            case let .setPopoverToDate(isPresented):
                state.popoverToDate = isPresented
                return .none

            case let .updateFromDateTapped(fromDate):
                // if from date is greater than toDate, update toDate to be last day in that month
                if fromDate > state.toDate {
                    state.toDate = fromDate.lastDayInMonth()
                }
                state.fromDate = fromDate
                return .none

            case let .updateToDateTapped(toDate):
                // Ensure date ranges are valid
                let cleanedToDate = toDate < state.fromDate ? state.fromDate.lastDayInMonth() : toDate
                state.toDate = cleanedToDate
                return .none

            case .runReportTapped:
                return .send(.delegate(.reportReadyToRun), animation: .smooth)

            case .selectAccountRowTapped:
                state.selectedAccounts = .init(budgetId: state.budgetId)
                return .none

            case .onAppear:
                // Ensure provided date is first day of month in FromDate
                // and last day of month ToDate
                state.fromDate = state.fromDate.firstDayInMonth()
                state.toDate = state.toDate.lastDayInMonth()
                return .none

            case .delegate, .selectAccounts:
                return .none
            }
        }
        .ifLet(\.$selectedAccounts, action: \.selectAccounts) {
            SelectAccountsFeature()
        }
    }
}

// MARK: - Date

private extension Date {

    static var firstDayOfLastMonth: Self {
        .now.advanceMonths(by: -1, strategy: .firstDay)
    }

    static var lastDayOfThisMonth: Self {
        .now.advanceMonths(by: 0, strategy: .lastDay)
    }
}
