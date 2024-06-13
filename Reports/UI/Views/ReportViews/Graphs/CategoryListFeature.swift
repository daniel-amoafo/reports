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
        var categoriesForCategoryGroupName: String?

        var isDisplayingSubCategory: Bool {
            contentType == .subCategories
        }

        var maybeCategoryName: String? {
            switch contentType {
            case .group:
                return nil
            case .subCategories:
                return categoriesForCategoryGroupName
            }
        }

        // Colors are mapped using Apple chart ordering
        func colorFor(_ record: AnyCategoryListItem) -> Color {
            // Default colors & ordering used in Apple Charts. This array is used to map the category colors
            // in the chart to the entries displayed in the list.
            let colors = [Color.blue, .green, .orange, .purple, .red, .cyan, .yellow]
            let index = listItems.firstIndex(of: record) ?? 0
            return colors[index % colors.count]
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
                    return .send(.delegate(.categoryGroupTapped(id: id)), animation: .smooth)

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

// MARK: -

/// Manages calls to Database queries
private enum CategoryListQueries {

    static let logger = LogFactory.create(Self.self)

    static var grdb: GRDBDatabase {
        @Dependency(\.database.grdb) var grdb
        return grdb
    }

    static func fetchTransactionEntries(for categoryId: String, fromDate: Date, toDate: Date, accountIds: String?)
    -> IdentifiedArrayOf<TransactionEntry> {
        do {
            let transactionsBuilder = TransactionEntry.queryTransactionsByCategoryId(
                categoryId,
                startDate: fromDate,
                finishDate: toDate,
                accountIds: accountIds
            )
            let transactions = try Self.grdb.fetchRecords(builder: transactionsBuilder)

            return .init(uniqueElements: transactions)
        } catch {
            Self.logger.error("\(error.toString())")
            return .init(uniqueElements: [])
        }
    }
}
