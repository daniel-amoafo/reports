// Created by Daniel Amoafo on 10/3/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftData
import SwiftUI

struct SavedReportsView: View {

    @Bindable var store: StoreOf<SavedReportsFeature>

    var body: some View {
        ZStack {
            Color.Surface.primary
                .ignoresSafeArea()

            if store.savedReports.isEmpty {
                Image(systemName: "binoculars.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.Text.secondary.opacity(0.7))
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.4
                    }
            } else {
                mainContent
            }
        }
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

    var mainContent: some View {
        List {
            ForEach(store.savedReports) { savedReport in
                Button {
                    store.send(.delegate(.rowTapped(savedReport.id)))
                } label: {
                    row(for: savedReport)
                }
            }
            .onDelete(perform: deleteEntry)
            .listRowBackground(Color.Surface.primary)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    func row(for savedReport: SavedReport) -> some View {
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

    func deleteEntry(at offsets: IndexSet) {
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

#Preview("No Results") {
    NavigationStack {
        SavedReportsView(
            store: withDependencies({
                try? $0.database.swiftData.delete(model: SavedReport.self)
            }, operation: {
                .init(initialState: .init()) {
                    SavedReportsFeature()
                }
            })
        )
    }
}
