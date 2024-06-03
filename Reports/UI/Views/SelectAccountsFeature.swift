// Created by Daniel Amoafo on 1/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct SelectAccountsFeature {

    @ObservableState
    struct State: Equatable {
        var activeAccounts: IdentifiedArrayOf<Account>
        var closedAccounts: IdentifiedArrayOf<Account>
        var activeAllAccounts: Bool = true
        var closedAllAccounts: Bool = true
        let budgetId: String
        @Shared(.wsValues) var workspaceValues

        init(budgetId: String) {
            self.budgetId = budgetId
            self.activeAccounts = []
            self.closedAccounts = []

            do {
                let activeAccounts = try Account.fetch(isOnBudget: true, isClosed: false, budgetId: budgetId)
                self.activeAccounts = .init(uniqueElements: activeAccounts)

                let closedAccounts = try Account.fetch(isOnBudget: true, isClosed: true, budgetId: budgetId)
                self.closedAccounts = .init(uniqueElements: closedAccounts)

                syncSelectedStates()
            } catch {
                let logger = LogFactory.create(Self.self)
                logger.error("\(error.toString())")
            }
        }

        var selectedAccountIdsSet: Binding<Set<String>> {
            .init {
                workspaceValues.selectedAccountIdsSet
            } set: {
                workspaceValues.selectedAccountIdsSet = $0
            }
        }

        var isAllActiveEnabled: Bool {
            selectedContainsAll(of: activeAccounts)
        }

        var isAllClosedEnabled: Bool {
            selectedContainsAll(of: closedAccounts)
        }

        func selectedContainsAll(of other: IdentifiedArrayOf<Account>) -> Bool {
            let otherSet = Set(other.elements.map(\.id))
            return workspaceValues.selectedAccountIdsSet.isSuperset(of: otherSet)
        }

        mutating func selectAll() {
            toggleAll(for: self.activeAccounts, isSelected: true)
            toggleAll(for: self.closedAccounts, isSelected: true)
        }

        mutating func deselectAll() {
            toggleAll(for: self.activeAccounts, isSelected: false)
            toggleAll(for: self.closedAccounts, isSelected: false)
        }

        mutating func syncSelectedStates () {
            activeAllAccounts = selectedContainsAll(of: activeAccounts)
            closedAllAccounts = selectedContainsAll(of: closedAccounts)
        }

        mutating func toggleAll(for other: IdentifiedArrayOf<Account>, isSelected: Bool) {
            let otherIds = other.elements.map(\.id)
            // Remove all other list ids from selectedIds
            workspaceValues.selectedAccountIdsSet = workspaceValues.selectedAccountIdsSet.filter {
                !otherIds.contains($0)
            }

            guard isSelected else { return }

            // Add all all other list ids to selectedIds
            for otherId in otherIds {
                workspaceValues.selectedAccountIdsSet.insert(otherId)
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case toggleActiveAll
        case toggleClosedAll
        case selectAll
        case deselectAll
    }

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .toggleActiveAll:
                state.activeAllAccounts.toggle()
                state.toggleAll(for: state.activeAccounts, isSelected: state.activeAllAccounts)
                return .none
            case .toggleClosedAll:
                state.closedAllAccounts.toggle()
                state.toggleAll(for: state.closedAccounts, isSelected: state.closedAllAccounts)
                return .none
            case .selectAll:
                state.selectAll()
                return .none
            case .deselectAll:
                state.deselectAll()
                return .none
            case .binding(\.workspaceValues.selectedAccountIdsSet):
                state.syncSelectedStates()
                return .none
            case .binding:
                return .none
            }
        }
    }
}
