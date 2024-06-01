// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct ReportInputFeature {

    @ObservableState
    struct State: Equatable {
        let chart: ReportChart
        var showChartMoreInfo = false
        var fromDate: Date = .now.advanceMonths(by: -1, strategy: .firstDay) // first day, last month
        var toDate: Date = .now.advanceMonths(by: 0, strategy: .lastDay) // last day, current month
        var accounts: IdentifiedArrayOf<Account>?
        var selectedAccountId: String?
        var showAccountList = false
        var popoverFromDate = false
        var popoverToDate = false

        // Return nil if the accountId is set to Account.allAccountsId.
        var santizedSelectedAccountId: String? {
            guard selectedAccountId != Account.allAccountsId else { return nil }
            return selectedAccountId
        }

        var selectedAccountName: String? {
            guard let selectedAccountId else { return nil }
            return accounts?[id: selectedAccountId]?.name
        }

        var isAccountSelected: Bool {
            selectedAccountId != nil
        }

        var isRunReportDisabled: Bool {
            !isAccountSelected
        }

        var fromDateFormatted: String { Date.iso8601local.string(from: fromDate) }
        var toDateFormatted: String { Date.iso8601local.string(from: toDate) }

        func isEqual(to savedReport: SavedReport) -> Bool {
            savedReport.fromDate == fromDateFormatted &&
            savedReport.toDate == toDateFormatted &&
            (savedReport.selectedAccountId == nil || savedReport.selectedAccountId == selectedAccountId)
        }

    }

    enum Action {
        case chartMoreInfoTapped
        case delegate(Delegate)
        case updateFromDateTapped(Date)
        case updateToDateTapped(Date)
        case selectAccountRowTapped(Bool)
        case didSelectAccountId(String?)
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
    @Dependency(\.database.grdb) var grdb

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

            case .delegate:
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

            case let .selectAccountRowTapped(isActive):
                state.showAccountList = isActive
                return .none

            case let .didSelectAccountId(accountId):
                state.selectedAccountId = accountId
                return .none

            case .onAppear:
                // Ensure provided date is first day of month in FromDate
                // and last day of month ToDate
                state.fromDate = state.fromDate.firstDayInMonth()
                state.toDate = state.toDate.lastDayInMonth()

                if state.accounts == nil {
                    do {
                        // List account Account Picker
                        let records = try Account.fetch(isOnBudget: true, isDeleted: false)
                        guard records.isNotEmpty else { return .none }
                        var accounts = IdentifiedArrayOf(uniqueElements: records)

                        // Add an 'All Accounts' to UI, if no selectedAcountId available, make this the selected
                        let allAccounts = Account.allAccounts
                        if accounts.insert(allAccounts, at: 0).inserted, state.selectedAccountId == nil {
                            state.selectedAccountId = allAccounts.id
                        }
                        state.accounts = accounts
                    } catch {
                        logger.error("\(String(describing: error))")
                    }
                }
                return .none
            }
        }
    }
}
