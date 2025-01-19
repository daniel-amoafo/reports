// Created by Daniel Amoafo on 21/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct OnboardingViewFeature {

    @ObservableState
    struct State {
        var budgetSummaries: IdentifiedArrayOf<BudgetSummary> = []
        var selectedBudgetId: String?

        var isLoading: Bool {
            budgetSummaries.isEmpty
        }

        var submitDisabled: Bool {
            selectedBudgetId == nil
        }

        var displayedBudgetId: String {
            guard let selectedBudgetId else { return "" }
            return budgetSummaries[id: selectedBudgetId]?.name ?? ""
        }

    }

    enum Action {
        case didSelectBudgetId(String?)
        case didUpdateBudgetSummaries(IdentifiedArrayOf<BudgetSummary>)
        case delegate(Delegate)
        case submitTapped
        case onAppear
    }

    @CasePathable
    enum Delegate {
        case didComplete
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.configProvider) var configProvider

    static let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .didSelectBudgetId(id):
                state.selectedBudgetId = id
                let selected = state.selectedBudgetId ?? ""
                Self.logger.debug("selectedBudgetId: \(selected)")
                return .none

            case let .didUpdateBudgetSummaries(summaries):
                state.budgetSummaries = summaries
                return .none

            case .submitTapped:
                guard let budgetId = state.selectedBudgetId else {
                    return .none
                }
                configProvider.setSelectedBudgetId( budgetId)

                return .send(.delegate(.didComplete), animation: .smooth)

            case .onAppear:
                return .run { send in
                    do {
                        let budgetSummaries = try await fetchBudgetSummaries()
                        await send(.didUpdateBudgetSummaries(budgetSummaries))
                    } catch {
                        Self.logger.error("\(error.toString())")
                    }
                }

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: -

 private extension OnboardingViewFeature {

    func fetchBudgetSummaries() async throws -> IdentifiedArrayOf<BudgetSummary> {
        let summaries = if await budgetClient.budgetSummaries.isEmpty {
            try await budgetClient.fetchBudgetSummaries()
        } else {
            await budgetClient.budgetSummaries
        }
        return .init(IdentifiedArrayOf(uniqueElements: summaries))
    }
 }
