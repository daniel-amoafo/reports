// Created by Daniel Amoafo on 22/4/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

// MARK: - View

struct ReportView: View {

    @Bindable var store: StoreOf<ReportFeature>

    var body: some View {
        VStack {
            scrollingContent
        }
        .popover(
          item: $store.scope(state: \.destination?.transactionHistory, action: \.destination.transactionHistory)
        ) { store in
            TransactionHistoryView(store: store)
                .presentationDetents([.medium])
        }
        .confirmationDialog($store.scope(state: \.confirmationDialog, action: \.confirmationDialog))
        .alert(
            Strings.saveReportAlertTitle,
            isPresented: $store.showSavedReportNameAlert.sending(\.showSavedReportNameAlert),
            actions: {
                TextField(Strings.saveReportPlaceholder, text: $store.savedReportName)
                Button(AppStrings.saveButtonTitle, action: { store.send(.savedReportName(shouldSave: true)) })
                    .disabled(store.savedReportName.isEmpty)
                Button(
                    AppStrings.cancelButtonTitle,
                    role: .cancel,
                    action: { store.send(.savedReportName(shouldSave: false)) }
                )
            }
        )
        .onAppear {
            store.send(.onAppear)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarLeading }
        .toolbar { toolbarPrincipal }
        .toolbar { toolbarTopTrailing }
        .background(Color.Surface.primary)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    var toolbarLeading: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            if !store.isNewReport {
                Button(Strings.editReportNameA11y, systemImage: "pencil.circle") {
                    store.send(.reportTitleTapped)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.Text.primary)
            }
        }
    }

    var toolbarPrincipal: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Button(store.reportTitle) {
                store.send(.reportTitleTapped)
            }
            .foregroundStyle(Color.Text.primary)
            .disabled(store.isNewReport)
        }
    }

    var toolbarTopTrailing: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(AppStrings.doneButtonTitle) {
                store.send(.doneButtonTapped)
            }
            .foregroundStyle(Color.Text.primary)
            .fontWeight(.bold)
        }
    }

}

private extension ReportView {

    var scrollingContent: some View {
        ScrollView {
            VStack(spacing: .Spacing.pt16) {
                ReportInputView(store: store.scope(state: \.inputFields, action: \.inputFields))

                HorizontalDivider()
                    .opacity(store.chartGraph == nil ? 0 : 1)

                chartGraphView
            }
            .scrollTargetLayout()
        }
        .contentMargins(.all, .Spacing.pt16, for: .scrollContent)
        .scrollPosition(id: $store.scrollToId, anchor: .top)
    }

    var chartGraphView: some View {
        VStack {
            if let store = store.scope(
                state: \.chartGraph?.spendingByTotal,
                action: \.chartGraph.spendingByTotal
            ) {
                SpendingTotalChartView(store: store)

            } else if let store = store.scope(
                state: \.chartGraph?.spendingByTrend,
                action: \.chartGraph.spendingByTrend
            ) {
                SpendingTrendChartView(store: store)
            }
        }
        .id(store.chartContainerId)
    }

}

// MARK: - Strings

private enum Strings {

    static let saveReportAlertTitle = String(
        localized: "Report Name", comment: "Title for alert when a report name is required for saving."
    )
    static let saveReportPlaceholder = String(
        localized: "Enter a report name", comment: "Placeholder text advising to enter a report name for saving."
    )

    static let editReportNameA11y = String(
        localized: "edit report name", comment: "tap to enter the saved report name"
    )
}

// MARK: - Previews

#Preview("Input Fields") {
    NavigationStack {
        ReportView(
            store: .init(initialState: Factory.mockInputFields) {
                ReportFeature()
            }
        )
    }
}

#Preview("Fetched Results") {
    NavigationStack {
        ReportView(
            store: .init(initialState: Factory.mockFetchedResults) {
                ReportFeature()
            }
        )
    }
}

#Preview("Fetched No Results") {
    NavigationStack {
        ReportView(
            store: .init(initialState: Factory.mockFetchedNoResults) {
                ReportFeature()
            }
        )
    }
}

// swiftlint:disable force_try
private enum Factory {

    static var selectedAccountIds: String {
        IdentifiedArrayOf<Account>.mocks[1].id
    }

    static var budgetId: String {
        IdentifiedArrayOf<BudgetSummary>.mocks[1].id
    }

    static var mockInputFields: ReportFeature.State {
        try! .init(
            sourceData: .new(
                .init(
                    chart: .mock,
                    budgetId: budgetId,
                    selectedAccountIds: selectedAccountIds,
                    selectedCategoryIds: .init()
                )
            )
        )
    }

    static var mockFetchedResults: ReportFeature.State {
        try! .init(
            sourceData: .new(
                .init(
                    chart: .mock,
                    budgetId: budgetId,
                    selectedAccountIds: selectedAccountIds
                )
            ),
            chartGraph: .spendingByTotal(
                .init(
                    title: "Spending By Total",
                    budgetId: Factory.budgetId,
                    startDate: Date.distantPast,
                    finishDate: Date.distantFuture,
                    accountIds: nil,
                    categoryIds: nil,
                    transactionEntries: Shared(value: nil)
                )
            )
        )
    }

    static var mockFetchedNoResults: ReportFeature.State {
        try! .init(
            sourceData: .new(
                .init(
                    chart: .mock,
                    budgetId: MockData.budgetId,
                    selectedAccountIds: selectedAccountIds,
                    selectedCategoryIds: .init()
                )
            )
        )
    }
}
// swiftlint:enable force_try
