// Created by Daniel Amoafo on 21/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct SelectCategoriesFeature {

    @ObservableState
    struct State: Equatable {
        var groups: IdentifiedArrayOf<CategoryGroup> = []
        var categories: IdentifiedArrayOf<Category> = []
        let budgetId: String
        var searchTerm: String = ""
        var searchFilteredCategories: IdentifiedArrayOf<Category>?
        @Shared var selected: Set<String>

        init(
            selected: Shared<Set<String>>,
            budgetId: String,
            groups: IdentifiedArrayOf<CategoryGroup>? = nil,
            categories: IdentifiedArrayOf<Category>? = nil
        ) {
            self.budgetId = budgetId
            self._selected = selected

            configureGroupsAndCategories(groups, categories)
        }

        mutating func configureGroupsAndCategories(
            _ groups: IdentifiedArrayOf<CategoryGroup>?,
            _ categories: IdentifiedArrayOf<Category>?
        ) {
            do {
                self.groups = if let groups {
                    groups
                } else {
                    .init(
                        uniqueElements: try CategoryGroup.fetch(isHidden: false, budgetId: budgetId)
                    )
                }

                self.categories = if let categories {
                    categories
                } else {
                    .init(
                        uniqueElements: try Category.fetch(isHidden: false, budgetId: budgetId)
                    )
                }

            } catch {
                let logger = LogFactory.create(Self.self)
                logger.error("\(error.toString())")
            }
        }

        func categoryIds(for groupId: String) -> [String] {
            categories(for: groupId).map(\.id)
        }

        func categories(for groupId: String) -> [Category] {
            guard let filteredCategories = searchFilteredCategories else {
                return categories.filter { $0.categoryGroupId == groupId }
            }
            return filteredCategories.filter { $0.categoryGroupId == groupId }
        }

        func isEntireGroupSelected(id: String) -> Bool {
            let categoryIds = categoryIds(for: id)
            return selectedContainsAll(of: categoryIds)
        }

        func selectedContainsAll(of other: [String]) -> Bool {
            let otherSet = Set(other)
            return selected.isSuperset(of: otherSet)
        }

        func isCategoryIdSelected(_ id: String) -> Bool {
            selected.contains(id)
        }

        func toggleGroupSelection(_ id: String, isSelected: Bool) {
            let categoryIds = Set(categoryIds(for: id))
            selected = selected.filter {
                !categoryIds.contains($0)
            }
            guard isSelected else { return }

            selected = selected.union(categoryIds)
        }

        func toggleCategoryIdSelection(_ id: String) {
            if isCategoryIdSelected(id) {
                selected.remove(id)
            } else {
                selected.insert(id)
            }
        }

        mutating func filterCategories(with searchTerm: String) {
            let filtered = categories.filter {
                $0.name.contains(searchTerm)
            }
            searchFilteredCategories = .init(filtered)
        }
    }

    enum Action {
        case categoryRowTapped(String)
        case groupRowTapped(String)
        case selectAll
        case deselectAll
        case searchTermChanged(String)
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .categoryRowTapped(id):
                state.toggleCategoryIdSelection(id)
                return .none

            case let .groupRowTapped(id):
                let isSelected = !state.isEntireGroupSelected(id: id)
                state.toggleGroupSelection(id, isSelected: isSelected)
                return .none

            case let .searchTermChanged(searchTerm):
                state.searchTerm = searchTerm
                guard searchTerm.isNotEmpty else {
                    state.searchFilteredCategories = nil
                    return .none
                }
                state.filterCategories(with: searchTerm)
                return .none

            case .selectAll:
                let allIds = state.categories.map(\.id)
                state.selected.removeAll()
                state.selected = .init(allIds)
                return .none

            case .deselectAll:
                state.selected.removeAll()
                return .none
            }
        }
    }
}
