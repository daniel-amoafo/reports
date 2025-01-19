// Created by Daniel Amoafo on 18/1/2025.

import ComposableArchitecture
import Foundation

@Reducer
struct SpendingHighLowChartFeature {

    @ObservableState
    struct State: Equatable {
        let title: String
        let budgetId: String
        let fromDate: Date
        let toDate: Date
        let accountIds: String?
    }

    enum Action {
        case onAppear
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
