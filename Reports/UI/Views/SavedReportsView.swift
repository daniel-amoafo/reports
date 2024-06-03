// Created by Daniel Amoafo on 10/3/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftData
import SwiftUI

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
                        let accountNames = store
                            .state.fetchAccountNamesOrDefaultToAll(ids: savedReport.selectedAccountIds)
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
                                    Text(accountNames)
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
