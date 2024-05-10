// Created by Daniel Amoafo on 10/3/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftData
import SwiftUI

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

    let logger = LogFactory.create(category: "SavedReportsFeature")

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .delete(offsets):
                let reportsToDelete = offsets.map { index in
                    state.savedReports[index]
                }
//                debugPrint("before savedReports - \(state.savedReports.count)")
//                state.savedReports = state.savedReports.filter { !reportsToDelete.contains($0) }
//                debugPrint("after savedReports - \(state.savedReports.count)")
                deleteSavedReports(reportsToDelete)
                return .none
            case .didUpdateSavedReports:
                state.savedReports = fetchSavedReports()
                return .none
            case .onAppear:
                return .send(.didUpdateSavedReports)
            case .onTask:
                return .run { send in
                    for await _ in await savedReportQuery.didUpdateNotification() {
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

    func fetchSavedReports() -> [SavedReport] {
        do {
            return try savedReportQuery.fetchAll()
        } catch {
            logger.error("\(error.localizedDescription)")
            return []
        }
    }

    func deleteSavedReports(_ reports: [SavedReport]) {
        for report in reports {
            do {
                try savedReportQuery.delete(report)
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }
}

struct SavedReportsView: View {

    @Bindable var store: StoreOf<SavedReportsFeature>

    var body: some View {
        List {
            if store.savedReports.isEmpty {
                Text("[Show No Saved Reports, create a report first]")
            } else {
                rowViews
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle(
            Text(Strings.title)
        )
        .onAppear {
            store.send(.onAppear)
        }
        .task {
            await store.send(.onTask).finish()
        }
    }
}

private extension SavedReportsView {

    var rowViews: some View {
        ForEach(store.savedReports) { savedReport in
            Button {
                store.send(.delegate(.rowTapped(report: savedReport)))
            } label: {
                HStack {
                    if let reportType = ReportChart.defaultCharts[id: savedReport.chartId] {
                        let accountName = store.state.fetchAccountNameOrDefaultToAll(id: savedReport.selectedAccountId)
                        reportType.type.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42.0, height: 42.0)
                        VStack(alignment: .leading) {
                            Text(savedReport.name)
                                .typography(.headlineEmphasized)
                                .foregroundStyle(Color.Text.primary)

                            HStack {
                                HStack {
                                    Image(systemName: "building.columns.fill")
                                    Text(accountName)
                                }
                            }
                            .font(Typography.subheadline.font)
                            .foregroundStyle(Color.Text.secondary)

                            HStack {
                                Image(systemName: "clock")
                                Text(savedReport.lastModifield.formatted(date: .abbreviated, time: .shortened))
                            }
                            .font(Typography.body.font)
                            .foregroundStyle(Color.Text.secondary)
                        }
                    }
                }
            }
        }
        .onDelete(perform: delete)
    }

    func delete(at offsets: IndexSet) {
        store.send(.delete(atOffsets: offsets))
    }

}

// MARK: -

private enum Strings {
    static let title = String(localized: "Saved Reports", comment: "The saved reports screen main title")
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SavedReportsView(
            store: .init(initialState: .init()) {
                SavedReportsFeature()
            }
        )
    }
}
