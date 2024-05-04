// Created by Daniel Amoafo on 22/4/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

@Reducer
struct ReportFeature {

    @ObservableState
    struct State: Equatable {
        var inputFields: ReportInputFeature.State
        @Presents var chartGraph: ChartGraph.State?
        @Presents var confirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog>?
        @Presents var destination: Destination.State?
        var scrollToId: String?
        var reportUpdated = false
        fileprivate let chartContainerId = "GraphChartContainer"

        var reportTitle: String {
            Strings.newReportTitle
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case inputFields(ReportInputFeature.Action)
        case chartGraph(PresentationAction<ChartGraph.Action>)
        case confirmationDialog(PresentationAction<ConfirmationDialog>)
        case destination(PresentationAction<Destination.Action>)
        case chartDisplayed
        case doneButtonTapped
        case onAppear

        enum ConfirmationDialog {
            case saveNewReport
            case updateExistingReport
            case discard
        }
    }

    @Reducer(state: .equatable)
    enum ChartGraph {
        case spendingByTotal(SpendingTotalChartFeature)
    }

    @Reducer(state: .equatable)
    enum Destination {
      case transactionHistory(TransactionHistoryFeature)
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.isPresented) var isPresented
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.inputFields, action: \.inputFields) {
            ReportInputFeature()
        }
        Reduce { state, action in
            switch action {
            case let .confirmationDialog(.presented(action)):
                switch action {
                case .saveNewReport:
                    // add save logic
                    break
                case .updateExistingReport:
                    break
                case .discard:
                    break
                }
                return .run { _ in
                    if isPresented {
                        await dismiss()
                    }
                }
            case .confirmationDialog:
                return .none

            case let .inputFields(.delegate(.fetchedTransactions(transactions))):
                switch state.inputFields.chart.type {
                case .spendingByTotal:
                    state.chartGraph = .spendingByTotal(.init(transactions: transactions))
                case .spendingByTrend:
                    break
                case .incomeExpensesTable:
                    break
                case .line:
                    break
                }
                state.reportUpdated = true
                state.scrollToId = nil
                return .run { send in
                    await send(.chartDisplayed, animation: .easeInOut)
                }
            case let .chartGraph(.presented(.spendingByTotal(.delegate(.categoryTapped(transactions))))):
                let array = transactions.elements
                state.destination = .transactionHistory(.init(transactions: array, title: array.first?.categoryName))
                return .none

            case .chartDisplayed:
                state.scrollToId = state.chartContainerId
                return .none

            case .doneButtonTapped:
                if state.reportUpdated {
                    state.confirmationDialog = makeConfirmDialog()
                    return .none
                } else {
                    return .run { _ in
                        if isPresented {
                            await dismiss()
                        }
                    }
                }

            case .onAppear, .inputFields, .chartGraph, .binding, .destination:
                return .none
            }
        }
        .ifLet(\.$chartGraph, action: \.chartGraph)
        .ifLet(\.$confirmationDialog, action: \.confirmationDialog)
        .ifLet(\.$destination, action: \.destination)
    }
}

private extension ReportFeature {

    func makeConfirmDialog() -> ConfirmationDialogState<Action.ConfirmationDialog> {
        .init {
            TextState("")
        } actions: {
            ButtonState(action: .saveNewReport) {
                TextState(AppStrings.saveButtonTitle)
            }
            ButtonState(role: .destructive, action: .discard) {
                TextState(Strings.confirmDiscard)
            }
            ButtonState(role: .cancel) {
                TextState(AppStrings.cancelButtonTitle)
            }
        } message: {
            TextState(Strings.confirmSaveNewReport)
        }
    }

}

// MARK: -

struct ReportView: View {

    @Bindable var store: StoreOf<ReportFeature>

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: .Spacing.pt16) {
                    ReportInputView(store: store.scope(state: \.inputFields, action: \.inputFields))

                    HorizontalDivider()
                        .opacity(store.chartGraph == nil ? 0 : 1)

                    if store.inputFields.isReportFetchingLoadingOrErrored {
                        searchingView
                    } else {
                        chartGraphView
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.all, .Spacing.pt16, for: .scrollContent)
            .scrollPosition(id: $store.scrollToId, anchor: .top)
        }
        .popover(
          item: $store.scope(state: \.destination?.transactionHistory, action: \.destination.transactionHistory)
        ) { store in
            TransactionHistoryView(store: store)
                .presentationDetents([.medium])
        }
        .confirmationDialog($store.scope(state: \.confirmationDialog, action: \.confirmationDialog))
        .task {
            store.send(.onAppear)
        }
        .navigationTitle(store.reportTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(AppStrings.doneButtonTitle) {
                store.send(.doneButtonTapped)
            }
            .foregroundStyle(Color.Text.primary)
            .fontWeight(.bold)
        }
        .background(Color.Surface.primary)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

}

private extension ReportView {

    var chartGraphView: some View {
        VStack {
            if let store = self.store.scope(
                state: \.chartGraph?.spendingByTotal, action: \.chartGraph.spendingByTotal
            ) {
                SpendingTotalChartView(store: store)
            }
        }
        .id(store.chartContainerId)
    }

    var searchingView: some View {
        VStack {
            Image(
                systemName: store.inputFields.isReportFetching ?
                "text.magnifyingglass" : "exclamationmark.magnifyingglass"
            )
            .resizable()
            .scaledToFit()
            .containerRelativeFrame(.horizontal) { length, _ in
                length * 0.5
            }
            .foregroundStyle(
                .linearGradient(colors: [.purple, .orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            // display pulsating image when actively searching
            .symbolEffect(.pulse.byLayer, options: .repeating, isActive: store.inputFields.isReportFetching)
            // switch from search with text image to exclaimation when there
            .contentTransition(store.inputFields.isReportFetching ? .identity : .symbolEffect(.replace.byLayer))
            .padding(.vertical)

            if case let .error(err) = store.inputFields.fetchStatus {
                Text(err.localizedDescription)
                    .typography(.bodyEmphasized)
                    .foregroundStyle(Color.Text.primary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Strings

private enum Strings {
    static let newReportTitle = String(localized: "New Report", comment: "the title when a new report is being created")
    static let confirmSaveNewReport = String(
        localized: "Save New Report?", comment: "Confirmation message when saving a new report message."
    )
    static let confirmDiscard = String(
        localized: "Discard", comment: "Confirmation action to not save changes & exit"
    )
}

// MARK: - Previews

#Preview("Input Fields") {
    NavigationStack {
        ReportView(
            store: .init(initialState: ReportFeature.mockInputFields) {
                ReportFeature()
            }
        )
    }
}

#Preview("Searching") {
    NavigationStack {
        ReportView(
            store: .init(initialState: ReportFeature.mockSearching) {
                ReportFeature()
            }
        )
    }
}

#Preview("Fetched Results") {
    NavigationStack {
        ReportView(
            store: .init(initialState: ReportFeature.mockFetchedResults) {
                ReportFeature()
            }
        )
    }
}

#Preview("Fetched No Results") {
    NavigationStack {
        ReportView(
            store: .init(initialState: ReportFeature.mockFetchedNoResults) {
                ReportFeature()
            }
        )
    }
}

private extension ReportFeature {

    static var selectedAccountId: String {
        IdentifiedArrayOf<Account>.mocks[0].id
    }

    static var mockInputFields: ReportFeature.State {
        .init(
            inputFields: .init(
                chart: .mock,
                accounts: .mocks,
                selectedAccountId: selectedAccountId
            )
        )
     }

    static var mockSearching: ReportFeature.State {
        .init(
            inputFields: .init(
                chart: .mock,
                accounts: .mocks,
                selectedAccountId: selectedAccountId,
                fetchStatus: .fetching
            )
        )
    }

    static var mockFetchedResults: ReportFeature.State {
        .init(
            inputFields: .init(
                chart: .mock,
                accounts: .mocks,
                selectedAccountId: selectedAccountId
            ),
            chartGraph: .spendingByTotal(.init(transactions: .mocks)),
            reportUpdated: true
        )
    }

    static var mockFetchedNoResults: ReportFeature.State {
        .init(
            inputFields: .init(
                chart: .mock,
                accounts: .mocks,
                selectedAccountId: selectedAccountId,
                fetchStatus: .error(.noResults)
            )
        )
    }
}
