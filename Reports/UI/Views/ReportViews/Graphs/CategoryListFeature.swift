// Created by Daniel Amoafo on 10/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct CategoryListFeature {

    enum CategorySelectionMode {
        case all
        case some
    }

    @ObservableState
    struct State: Equatable {

        let contentType: CategoryType
        let fromDate: Date
        let toDate: Date
        var accountIds: String?
        let listItems: [AnyCategoryListItem]
        var categoryGroupName: String?
        let chartNameColor: ChartNameColor
        let categorySelectionMode: CategorySelectionMode
        @Shared var transactionEntries: [TransactionEntry]?

        var isDisplayingSubCategory: Bool {
            contentType == .subCategories
        }

        var primaryLabel: String {
            categorySelectionMode.title
        }

        var maybeCategoryName: String? {
            switch contentType {
            case .group:
                return nil
            case .subCategories:
                return categoryGroupName
            }
        }

        // Colors are mapped using Apple chart ordering
        func colorFor(_ name: String) -> Color {
            return chartNameColor.colorFor(name)
        }

    }

    enum Action {
        case listRowTapped(id: String)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case categoryGroupTapped(id: String)
            case subTitleTapped
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .listRowTapped(id):
                switch state.contentType {
                case .group:
                    return .send(.delegate(.categoryGroupTapped(id: id)))

                case .subCategories:
                    let transactions = CategoryListQueries.fetchTransactionEntries(
                        for: id,
                        fromDate: state.fromDate,
                        toDate: state.toDate,
                        accountIds: state.accountIds
                    )
                    state.transactionEntries = transactions.elements
                    return .none
                }

            case .delegate:
                return .none
            }
        }
    }
}

extension CategoryListFeature.State {

    static var empty: Self {
        .init(
            contentType: .group,
            fromDate: .distantPast,
            toDate: .distantFuture,
            listItems: [],
            chartNameColor: .init(names: []),
            categorySelectionMode: .all,
            transactionEntries: Shared(nil)
        )
    }
}

extension CategoryListFeature.CategorySelectionMode {

    var title: String {
        switch self {
        case .all:
            AppStrings.allCategoriesTitle
        case .some:
            AppStrings.someCategoriesTitle
        }
    }
}
