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
        var scrollToId: String?

        fileprivate let chartContainerId = "GraphChartContainer"
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case inputFields(ReportInputFeature.Action)
        case chartGraph(PresentationAction<ChartGraph.Action>)
        case chartDisplayed
        case onAppear
    }

    @Reducer(state: .equatable)
    enum ChartGraph {
        case spendingByTotal(SpendingTotalChartFeature)
    }

    @Dependency(\.budgetClient) var budgetClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.inputFields, action: \.inputFields) {
            ReportInputFeature()
        }
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .chartGraph:
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
                state.scrollToId = nil
                return .run { send in
                    await send(.chartDisplayed, animation: .easeInOut)
                }
            case .chartDisplayed:
                state.scrollToId = state.chartContainerId
                return .none
            case .inputFields:
                return .none
            case .onAppear:
                return .none
            }
        }
        .ifLet(\.$chartGraph, action: \.chartGraph)
        ._printChanges()
    }
}

private enum Strings {
    static let newReportTitle = String(localized: "New Report", comment: "the title when a new report is being created")

}

struct ReportView: View {

    @Bindable var store: StoreOf<ReportFeature>

    var body: some View {
        ZStack {
            Color(.Surface.primary)
                .ignoresSafeArea()
            VStack(spacing: .Spacing.pt8) {
                Text(Strings.newReportTitle)
                    .typography(.title2Emphasized)
                ScrollView {
                    VStack(spacing: .Spacing.pt16) {
                        ReportInputView(store: store.scope(state: \.inputFields, action: \.inputFields))

                        HorizontalDivider()
                            .opacity(store.chartGraph == nil ? 0 : 1)

                        chartGraphView
                            .id(store.chartContainerId)
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.all, .Spacing.pt16, for: .scrollContent)
                .scrollPosition(id: $store.scrollToId, anchor: .top)
            }
        }
        .task {
            store.send(.onAppear)
        }
    }

    var chartGraphView: some View {
        VStack {
            if let store = self.store.scope(
                state: \.chartGraph?.spendingByTotal, action: \.chartGraph.spendingByTotal
            ) {
                SpendingTotalChartView(store: store)
            }
        }
    }
}

// MARK: -

#Preview {
    ReportView(
        store: .init(initialState: ReportFeature.mockState) {
            ReportFeature()
        }
    )
}

private extension ReportFeature {

    static var mockState: ReportFeature.State {
        .init(inputFields: .init(chart: .mock, accounts: .mocks))
     }
}
