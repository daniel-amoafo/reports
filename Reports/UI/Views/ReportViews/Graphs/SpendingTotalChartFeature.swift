// Created by Daniel Amoafo on 5/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import MoneyCommon

enum CategoryType: Equatable, Sendable {
    case group
    case subCategories
}
// this is a really long long this is a really long long this is a really long long this is a really long long this is a really long long
@Reducer
struct SpendingTotalChartFeature {

    @ObservableState
    struct State: Equatable {
        let title: String
        let startDate: Date
        let finishDate: Date
        let accountIds: String?
        var contentType: CategoryType = .group

        var rawSelectedGraphValue: Decimal?
        var selectedGraphItem: CategoryRecord?

        fileprivate let categoryGroups: [CategoryRecord]

        // Categories for a given categoryGroup.
        // Updated when user selects a categoryGroup to inspect
        fileprivate var catgoriesForCategoryGroup: [CategoryRecord] = []
        fileprivate var categoriesForCategoryGroupName: String?

        init(
            title: String,
            budgetId: String,
            startDate: Date,
            finishDate: Date,
            accountIds: String?,
            categoryGroups: [CategoryRecord]? = nil
        ) {
            self.title = title
            self.startDate = startDate
            self.finishDate = finishDate
            self.accountIds = accountIds

            self.categoryGroups = if let categoryGroups {
                categoryGroups
            } else {
                CategoryListQueries.fetchCategoryGroupTotals(
                    budgetId: budgetId,
                    fromDate: startDate,
                    toDate: finishDate,
                    accountIds: accountIds
                )
            }
        }

        var hasResults: Bool {
            categoryGroups.isNotEmpty
        }

        var selectedContent: [CategoryRecord] {
            switch contentType {
            case .group:
                return categoryGroups
            case .subCategories:
                return catgoriesForCategoryGroup
            }
        }

        var totalName: String {
            switch contentType {
            case .group:
                return AppStrings.allCategoriesTitle
            case .subCategories:
                return String(format: Strings.categoryNameTotal, (categoriesForCategoryGroupName ?? ""))
            }
        }

        var grandTotalValue: String {
            let selected = selectedContent
            guard let currency = selected.first?.total.currency else {
                return ""
            }
            // tally up all the totals for each record to provide a grand total
            let total = selected.map(\.total).reduce(.zero(currency), +)
            return total.amountFormatted
        }

        var listSubTitle: String {
            switch contentType {
            case .group, .subCategories:
                return AppStrings.allCategoriesTitle
            }
        }

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
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case listRowTapped(id: String)
        case catgoriesForCategoryGroupFetched([CategoryRecord], String)
        case subTitleTapped

        @CasePathable
        enum Delegate {
            case categoryTapped(IdentifiedArrayOf<TransactionEntry>)
        }
    }

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.rawSelectedGraphValue):
                guard let rawSelected = state.rawSelectedGraphValue else {
                    state.selectedGraphItem = nil
                    return .none
                }
                var cumulative = Decimal.zero
                // This approach is lifted from Apple's interactive pie chart WWDC talk
                // see https://developer.apple.com/wwdc23/10037
                let cumulativeArea = state.selectedContent.map {
                    let newCumulative = cumulative + abs($0.total.amount)
                    let result = (id: $0.id, range: cumulative ..< newCumulative)
                    cumulative = newCumulative
                    return result
                }

                guard let foundEntry = cumulativeArea
                    .first(where: { $0.range.contains(rawSelected) }),
                      let item = state.selectedContent.first(where: { $0.id == foundEntry.id })
                else { return .none }
                state.selectedGraphItem = item
                return .none

            case let .catgoriesForCategoryGroupFetched(records, categoryGroupName):
                state.catgoriesForCategoryGroup = records
                state.categoriesForCategoryGroupName = categoryGroupName
                state.contentType = .subCategories
                state.selectedGraphItem = nil
                return .none

            case let .listRowTapped(id):
                switch state.contentType {
                case .group:
                    let (records, groupName) = SpendingTotalQueries.fetchCategoryTotals(
                        categoryGroupId: id,
                        startDate: state.startDate,
                        finishDate: state.finishDate,
                        accountIds: state.accountIds
                    )
                    return .send(.catgoriesForCategoryGroupFetched(records, groupName), animation: .smooth)

                case .subCategories:
                    let transactions = SpendingTotalQueries.fetchTransactionEntries(
                        for: id,
                        startDate: state.startDate,
                        finishDate: state.finishDate,
                        accountIds: state.accountIds
                    )
                    return .send(.delegate(.categoryTapped(transactions)), animation: .smooth)
                }

            case .subTitleTapped:
                state.contentType = .group
                state.catgoriesForCategoryGroup = []
                state.categoriesForCategoryGroupName = nil
                state.selectedGraphItem = nil
                return .none

            case .binding,
                    .delegate:
                return .none
            }
        }
    }
}

// MARK: -

/// Manages calls to Database queries
private enum SpendingTotalQueries {

    static let logger = LogFactory.create(Self.self)

    static var grdb: GRDBDatabase {
        @Dependency(\.database.grdb) var grdb
        return grdb
    }

    static func fetchCategoryTotals(
        categoryGroupId: String,
        startDate: Date,
        finishDate: Date,
        accountIds: String?
    ) -> ([CategoryRecord], String) {
        do {
            let categoryBuilder = CategoryRecord
                .queryTransactionsByCategoryTotals(
                    forCategoryGroupId: categoryGroupId,
                    startDate: startDate,
                    finishDate: finishDate,
                    accountIds: accountIds
                )
            let records = try Self.grdb.fetchRecords(builder: categoryBuilder)

            let groupName = try CategoryGroup.fetch(id: categoryGroupId)?.name ?? ""

            return (records, groupName)
        } catch {
            Self.logger.error("\(error.toString())")
            return ([], "")
        }
    }

    static func fetchTransactionEntries(for categoryId: String, startDate: Date, finishDate: Date, accountIds: String?)
    -> IdentifiedArrayOf<TransactionEntry> {
        do {
            let transactionsBuilder = TransactionEntry.queryTransactionsByCategoryId(
                categoryId,
                startDate: startDate,
                finishDate: finishDate,
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

// MARK: -

private enum Strings {

    static let categoryNameTotal = String(
        localized: "%@ Total",
        comment: "A category total. %@ = The selected category"
    )

}
