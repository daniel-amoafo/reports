// Created by Daniel Amoafo on 21/6/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

struct SelectCategoriesView: View {

    @Bindable var store: StoreOf<SelectCategoriesFeature>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(store.groups) { group in
                maybeGroupView(for: group)
            }
            .scrollContentBackground(.hidden)
            .background(Color.Surface.primary)
            .toolbar { toolbarTopLeading }
            .toolbar { toolbarTopTrailing }
            .searchable(text: $store.searchTerm.sending(\.searchTermChanged))
        }
    }
}

private extension SelectCategoriesView {

    var toolbarTopLeading: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            HStack {
                Button(AppStrings.selectAll) {
                    store.send(.selectAll, animation: .smooth)
                }
                .foregroundStyle(Color.Text.secondary)

                Text("|")

                Button(AppStrings.deselectAll) {
                    store.send(.deselectAll, animation: .smooth)
                }
            }
            .foregroundStyle(Color.Text.secondary)
        }
    }

    var toolbarTopTrailing: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(AppStrings.doneButtonTitle) {
                dismiss()
            }
            .foregroundStyle(Color.Text.primary)
        }
    }

    @ViewBuilder
    func maybeGroupView(for group: CategoryGroup) -> some View {
        let categories = store.state.categories(for: group.id)
        if categories.isNotEmpty {
            Section {
                ForEach(categories) { category in
                    categoryView(for: category)
                }
            } header: {
                categoryHeaderRow(for: group)
            }
            .listRowBackground(Color.Surface.secondary)
        }
    }

    func categoryHeaderRow(for group: CategoryGroup) -> some View {
        Button {
            store.send(.groupRowTapped(group.id), animation: .smooth)
        } label: {
            HStack {
                Text(group.name)
                    .typography(.subheadlineEmphasized)
                    .foregroundStyle(Color.Text.secondary)

                Spacer()
                rowViewImage(store.state.isEntireGroupSelected(id: group.id))
            }
            .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.Button.primary)
    }

    func categoryView(for category: Category) -> some View {
        Button {
            store.send(.categoryRowTapped(category.id), animation: .smooth)
        } label: {
            HStack {
                Text(category.name)
                    .typography(.bodyEmphasized)
                Spacer()
                rowViewImage(store.state.isCategoryIdSelected(category.id))
            }
            .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
    }

    func rowViewImage(_ isSelected: Bool) -> some View {
        Image(
            systemName: isSelected ? "square.inset.filled" : "square"
        )
        .symbolRenderingMode(.hierarchical)
    }
}

// MARK: - Previews

#Preview {
    SelectCategoriesView(
        store: .init(initialState: PreviewFactory.stateWithSelectedValues) {
            SelectCategoriesFeature()
        }
    )
}

private enum PreviewFactory {

    static let budgetId = IdentifiedArrayOf<BudgetSummary>.mocks[0].id

    static var stateWithSelectedValues: SelectCategoriesFeature.State {
        .init(
            selected: Shared(selectedCategories),
            budgetId: budgetId
        )
    }

    static var selectedCategories: Set<String> {
        let transportation = Set(Category.fetchMockData(byCategoryGroupId: "CG-TRANS").map(\.id))
        let fixedExpenses = Set([Category.fetchMockData(byName: "Groceries").id])
        return transportation.union(fixedExpenses)
    }
}

// private extension SelectedCategories {
//
//    static var transportation: Self {
//        .init(
//            groupId: CategoryGroup.fetchMockData(name: "Transportation").id,
//            categoryIds: Set(Category.fetchMockData(byCategoryGroupId: "CG-TRANS").map(\.id))
//        )
//    }
//
//    static var fixedExpenses: Self {
//        .init(
//            groupId: CategoryGroup.fetchMockData(name: "Fixed Expenses").id,
//            categoryIds: Set(
//                [Category.fetchMockData(byName: "Groceries").id]
//            )
//        )
//    }
// }
