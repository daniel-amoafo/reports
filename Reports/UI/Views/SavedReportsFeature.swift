// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct SavedReportsFeature {

    @ObservableState
    struct State: Equatable {
        var savedReports: [SavedReport] = []

        func fetchAccountNameOrDefaultToAll(id: String?) -> String {
            @Dependency(\.budgetClient) var budgetClient
            guard let id,
                  let name = budgetClient.accounts[id: id]?.name
            else {
                return Account.allAccounts.name
            }
            return name
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
                    for await _ in await modelContextNotifications.didUpdate(SavedReport.self) {
                        await send(.didUpdateSavedReports, animation: .smooth)
                    }
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
