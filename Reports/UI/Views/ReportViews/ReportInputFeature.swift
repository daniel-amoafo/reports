// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct ReportInputFeature {

    @ObservableState
    struct State {
        let chart: ReportChart
        let budgetId: String
        var showChartMoreInfo = false
        var fromDate: Date
        var toDate: Date
        var selectedAccountIdsSet: Set<String>
        @Presents var selectedAccounts: SelectAccountsFeature.State?
        var popoverFromDate = false
        var popoverToDate = false

        private let accounts: IdentifiedArrayOf<Account>

        private let logger = LogFactory.create(Self.self)

        init(
            chart: ReportChart,
            budgetId: String,
            fromDate: Date = .now.advanceMonths(by: -1, strategy: .firstDay), // first day, last month
            toDate: Date = .now.advanceMonths(by: 0, strategy: .lastDay), // last day, current month
            selectedAccountIds: String? = nil
        ) {
            self.chart = chart
            self.budgetId = budgetId
            self.fromDate = fromDate
            self.toDate = toDate
            self.selectedAccountIdsSet = Self.setSelectedAccountIds(selectedAccountIds)
            self.accounts = Self.fetchAccounts(budgetId: budgetId)
        }

        static func setSelectedAccountIds(_ ids: String?) -> Set<String> {
            guard let ids else { return .init() }
            let array = ids
                .split(separator: ",")
                .map { String($0) }
            return Set(array)
        }

        static func fetchAccounts(budgetId: String) -> IdentifiedArrayOf<Account> {
            do {
                let accounts = try Account.fetchAll(budgetId: budgetId)
                return .init(uniqueElements: accounts)
            } catch {
                let logger = LogFactory.create(Self.self)
                logger.error("\(error.toString())")
                return []
            }
        }

        var selectedAccountIds: String? {
            guard selectedAccountIdsSet.isNotEmpty else { return nil }
            return selectedAccountIdsSet.joined(separator: ",")
        }

        var selectedAccountNames: String? {
            guard selectedAccountIdsSet.isNotEmpty else { return nil }
            let names = accounts.filter {
                selectedAccountIdsSet.contains($0.id)
            }.map(\.name).joined(separator: ", ")
            return names
        }

        var isRunReportDisabled: Bool {
            false // probably no longer needed due to All Accounts changes
        }

        var fromDateFormatted: String { Date.iso8601local.string(from: fromDate) }
        var toDateFormatted: String { Date.iso8601local.string(from: toDate) }

        func isEqual(to savedReport: SavedReport) -> Bool {
            savedReport.fromDate == fromDateFormatted &&
            savedReport.toDate == toDateFormatted &&
            savedReport.selectedAccountIds == selectedAccountIds
        }
    }

    enum Action {
        case chartMoreInfoTapped
        case delegate(Delegate)
        case selectAccounts(PresentationAction<SelectAccountsFeature.Action>)
        case updateFromDateTapped(Date)
        case updateToDateTapped(Date)
        case selectAccountRowTapped
        case setPopoverFromDate(Bool)
        case setPopoverToDate(Bool)
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
        Reduce { state, action in
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
                state.selectedAccounts = .init(
                    budgetId: state.budgetId, selectedIds: Shared(state.selectedAccountIdsSet)
                )

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
