// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct SavedReportsFeature {

    @ObservableState
    struct State: Equatable {
        var savedReports: [SavedReport]
        @Shared(.workspaceValues) var workspaceValues

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
            return workspaceValues.accountOnBudgetNames(for: ids) ?? ""
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

    enum Action: Sendable {
        case didUpdateSavedReports
        case delete(atOffsets: IndexSet)
        case delegate(Delegate)
        case onAppear
        case onTask
    }

    @CasePathable
    enum Delegate: Sendable {
        case rowTapped(UUID)
    }

    // MARK: Dependencies
    @Dependency(\.modelContextNotifications) var modelContextNotifications

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .delete(offsets):
                let reportsToDelete = offsets.map { index in
                    state.savedReports[index]
                }
                state.deleteSavedReports(reportsToDelete)
                return .none

            case .didUpdateSavedReports:
                state.fetchSavedReports()
                return .none

            case .onAppear:
                state.fetchSavedReports()
                return .none

            case .onTask:
                return .run { send in
                    await Task { @MainActor in
                        for await _ in await modelContextNotifications.didUpdate(SavedReport.self) {
                            send(.didUpdateSavedReports, animation: .smooth)
                        }
                    }.value

                    // mointor when selected budgetId changes and update saved reports
                }

            case .delegate:
                return .none
            }
        }
    }
}

private extension SavedReportsFeature.State {

    var savedReportQuery: SavedReportQuery {
        @Dependency(\.savedReportQuery) var savedReportQuery
        return savedReportQuery
    }

    mutating func fetchSavedReports() {
        do {
            savedReports = try savedReportQuery.fetchAll()
        } catch {
            let logger = LogFactory.create(Self.self)
            logger.error("\(error.toString())")
        }
    }

    func deleteSavedReports(_ reports: [SavedReport]) {
        for report in reports {
            do {
                try savedReportQuery.delete(report)
            } catch {
                let logger = LogFactory.create(Self.self)
                logger.error("\(error.toString())")
            }
        }
    }
}
