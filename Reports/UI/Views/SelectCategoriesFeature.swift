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
        var isOnlySelectedFilter: Bool = false
        @Shared var selected: Set<String>

        init(
            selected: Shared<Set<String>>,
            budgetId: String,
            groups: IdentifiedArrayOf<CategoryGroup>? = nil,
            categories: IdentifiedArrayOf<Category>? = nil,
            isOnlySelectedFilter: Bool = false
        ) {
            self.budgetId = budgetId
            self.isOnlySelectedFilter = isOnlySelectedFilter
            self._selected = selected

            configureGroupsAndCategories(groups, categories)
        }

        private var listCategories: IdentifiedArrayOf<Category> {
            if let searchFilteredCategories {
                searchFilteredCategories
            } else if isOnlySelectedFilter {
                .init(uniqueElements: selectedCategories)
            } else {
                categories
            }
        }

        var selectedCategories: [Category] {
            selected
                .compactMap { categories[id: $0] }
                .sorted { $0.name < $1.name }
        }

        var noResultsLabel: String? {
            guard listCategories.isEmpty else { return nil }
            if let searchFilteredCategories, searchFilteredCategories.isEmpty {
                return Strings.noSearchResults
            } else if isOnlySelectedFilter {
                return Strings.noSelectedCategories
            }
            return nil
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
            return listCategories.filter { $0.categoryGroupId == groupId }
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
        case searchTermChanged(String)
        case onlySelectedCategoryToggled
        case selectAll
        case deselectAll
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

            case .onlySelectedCategoryToggled:
                state.isOnlySelectedFilter.toggle()
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

private enum Strings {

    static let noSearchResults = String(
        localized: "No matches for search results.",
        comment: "Message when no categories match search string"
    )

    static let noSelectedCategories = String(
        localized: "No categories selected.",
        comment: "Message when no categories have been selected yet"
    )
}
