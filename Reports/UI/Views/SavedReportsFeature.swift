// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct SavedReportsFeature {

    @ObservableState
    struct State: Equatable {
        var savedReports: [SavedReport]
        @Shared(.wsValues) var workspaceValues

        init(savedReports: [SavedReport] = []) {
            self.savedReports = savedReports
        }

        func fetchAccountNamesOrDefaultToAll(ids: String?) -> String {
            guard let ids else {
                let logger = LogFactory.create(Self.self)
                logger.warning(
                    "Should not have nil account ids associated to a saved report. This seems to be an error."
                )
                return ""
            }
            return workspaceValues.accountNames(for: ids) ?? ""
        }

        static func loadAccountNames(for maybeBudgetId: String?) -> [String: String] {
            let budgetId: String
            if let maybeBudgetId {
                budgetId = maybeBudgetId
            } else {
                @Dependency(\.configProvider) var configProvider
                guard let abudgetId = configProvider.selectedBudgetId else {
                    return [:]
                }
                budgetId = abudgetId
            }

            let accountsArray = try? Account.fetchAll(budgetId: budgetId)
            // get available account names using id as key
            let names = (accountsArray ?? [])
                .reduce(into: [String: String]()) {
                    $0[$1.id] = $1.name
                }
            return names
        }
    }

    enum Action {
        case didUpdateSavedReports
        case delete(atOffsets: IndexSet)
        case delegate(Delegate)
        case onAppear
        case onTask
    }

    @CasePathable
    enum Delegate {
        case rowTapped(report: SavedReport)
    }

    // MARK: Dependencies
    @Dependency(\.savedReportQuery) var savedReportQuery
    @Dependency(\.modelContextNotifications) var modelContextNotifications

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .delete(offsets):
                let reportsToDelete = offsets.map { index in
                    state.savedReports[index]
                }
                deleteSavedReports(reportsToDelete)
                return .none

            case .didUpdateSavedReports:
                return fetchSavedReports(state: &state)

            case .onAppear:
                return fetchSavedReports(state: &state)

            case .onTask:
                return .run { send in
                    Task { @MainActor in
                        for await _ in await modelContextNotifications.didUpdate(SavedReport.self) {
                            send(.didUpdateSavedReports, animation: .smooth)
                        }
                    }

                    // mointor when selected budgetId changes and update saved reports
                }

            case .delegate:
                return .none
            }
        }
    }
}

fileprivate extension SavedReportsFeature {

    func fetchSavedReports(state: inout State) -> Effect<Action> {
        do {
            state.savedReports = try savedReportQuery.fetchAll()
            return .none
        } catch {
            logger.error("\(error.toString())")
            return .none
        }
    }

    func deleteSavedReports(_ reports: [SavedReport]) {
        for report in reports {
            do {
                try savedReportQuery.delete(report)
            } catch {
                logger.error("\(error.toString())")
            }
        }
    }
}
