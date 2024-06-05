// Created by Daniel Amoafo on 5/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import MoneyCommon

@Reducer
struct SpendingTotalChartFeature {

    @ObservableState
    struct State: Equatable {
        let title: String
        let startDate: Date
        let finishDate: Date
        let accountIds: String?
        var contentType: SpendingTotalChartFeature.ContentType = .categoryGroup

        var rawSelectedGraphValue: Decimal?
        var selectedGraphItem: CategoryRecord?

        fileprivate var categoryGroups: [CategoryRecord] = []

        // Categories for a given categoryGroup.
        // Updated when user selects a categoryGroup to inspect
        fileprivate var catgoriesForCategoryGroup: [CategoryRecord] = []
        fileprivate var catgoriesForCategoryGroupName: String?

        init(
            title: String,
            budgetId: String,
            startDate: Date,
            finishDate: Date,
            accountIds: String?
        ) {
            self.title = title
            self.startDate = startDate
            self.finishDate = finishDate
            self.accountIds = accountIds

            self.categoryGroups = SpendingTotalQueries.fetchCategoryGroupTotals(
                budgetId: budgetId, startDate: startDate, finishDate: finishDate, accountIds: accountIds
            )
        }

        var selectedContent: [CategoryRecord] {
            switch contentType {
            case .categoryGroup:
                return categoryGroups
            case .categoriesByCategoryGroup:
                return catgoriesForCategoryGroup
            }
        }

        var totalName: String {
            switch contentType {
            case .categoryGroup:
                return AppStrings.allCategoriesTitle
            case .categoriesByCategoryGroup:
                return String(format: Strings.categoryNameTotal, (catgoriesForCategoryGroupName ?? ""))
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
            case .categoryGroup, .categoriesByCategoryGroup:
                return AppStrings.allCategoriesTitle
            }
        }

        var isDisplayingSubCategory: Bool {
            contentType == .categoriesByCategoryGroup
        }

        var maybeCategoryName: String? {
            switch contentType {
            case .categoryGroup:
                return nil
            case .categoriesByCategoryGroup:
                return catgoriesForCategoryGroupName
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case listRowTapped(id: String)
        case catgoriesForCategoryGroupFetched([CategoryRecord], String)
        case subTitleTapped
        case onAppear

        @CasePathable
        enum Delegate {
            case categoryTapped(IdentifiedArrayOf<TransactionEntry>)
        }
    }

    enum ContentType: Equatable {
        case categoryGroup
        case categoriesByCategoryGroup
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.database.grdb) var grdb

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
                state.catgoriesForCategoryGroupName = categoryGroupName
                state.contentType = .categoriesByCategoryGroup
                state.selectedGraphItem = nil
                return .none

            case let .listRowTapped(id):
                switch state.contentType {
                case .categoryGroup:
                    let (records, groupName) = SpendingTotalQueries.fetchCategoryTotals(
                        categoryGroupId: id,
                        startDate: state.startDate,
                        finishDate: state.finishDate,
                        accountIds: state.accountIds
                    )
                    return .send(.catgoriesForCategoryGroupFetched(records, groupName), animation: .smooth)

                case .categoriesByCategoryGroup:
                    let transactions = SpendingTotalQueries.fetchTransactionEntries(
                        for: id,
                        startDate: state.startDate,
                        finishDate: state.finishDate,
                        accountIds: state.accountIds
                    )
                    return .send(.delegate(.categoryTapped(transactions)), animation: .smooth)
                }

            case .subTitleTapped:
                state.contentType = .categoryGroup
                state.catgoriesForCategoryGroup = []
                state.catgoriesForCategoryGroupName = nil
                state.selectedGraphItem = nil
                return .none

            case .onAppear:
                return .none

            case .binding,
                    .delegate:
                return .none
            }
        }
    }
}

/// Manages calls to Database queries
private enum SpendingTotalQueries {

    static let logger = LogFactory.create(Self.self)

    static var grdb: GRDBDatabase {
        @Dependency(\.database.grdb) var grdb
        return grdb
    }

    static func fetchCategoryGroupTotals(
        budgetId: String,
        startDate: Date,
        finishDate: Date,
        accountIds: String?
    ) -> [CategoryRecord] {
        do {
            let categoryGroupBuilder = CategoryRecord
                .queryTransactionsByCategoryGroupTotals(
                    budgetId: budgetId,
                    startDate: startDate,
                    finishDate: finishDate,
                    accountIds: accountIds
                )

            return try grdb.fetchRecords(builder: categoryGroupBuilder)
        } catch {
            logger.error("\(String(describing: error))")
            return []
        }
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
        comment: "A category total. %@ = The selected category "
    )

}
