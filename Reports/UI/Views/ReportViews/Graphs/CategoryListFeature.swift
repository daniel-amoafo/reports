// Created by Daniel Amoafo on 10/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct CategoryListFeature {

    @ObservableState
    struct State: Equatable {

        var contentType: CategoryType
        var fromDate: Date
        var toDate: Date
        var accountIds: String?
        var listItems: [AnyCategoryListItem]
        var categoryGroupName: String?
        var chartNameColor: ChartNameColor

        var isDisplayingSubCategory: Bool {
            contentType == .subCategories
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
            case categoryTapped(IdentifiedArrayOf<TransactionEntry>)
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
                    return .send(.delegate(.categoryTapped(transactions)), animation: .smooth)
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
            chartNameColor: .init(names: [])
        )
    }
}
