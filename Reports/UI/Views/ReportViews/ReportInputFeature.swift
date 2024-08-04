// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct ReportInputFeature {

    @ObservableState
    struct State: Equatable, Sendable {
        let chart: ReportChart
        let budgetId: String
        var showChartMoreInfo = false
        var fromDate: Date
        var toDate: Date
        @Shared(.workspaceValues) var workspaceValues
        @Presents var selectedAccounts: SelectAccountsFeature.State?
        @Presents var selectedCategories: SelectCategoriesFeature.State?
        var popoverFromDate = false
        var popoverToDate = false
        @Shared var selectedCategoryIdsSet: Set<String>
        private var categories: IdentifiedArrayOf<Category> = .init(uniqueElements: [])

        init(
            chart: ReportChart,
            budgetId: String,
            fromDate: Date = Date.firstDayOfLastMonth,
            toDate: Date = Date.lastDayOfThisMonth,
            selectedAccountIds: String? = nil,
            selectedCategoryIds: String? = nil
        ) {
            self.chart = chart
            self.budgetId = budgetId
            self.fromDate = fromDate
            self.toDate = toDate
            self._selectedCategoryIdsSet = Shared(WorkspaceValues.makeSet(for: selectedCategoryIds))
            self.workspaceValues.updateSelectedAccountIds(ids: selectedAccountIds)

            setCategories()
        }

        var selectedAccountIds: String? {
            workspaceValues.selectedAccountIds
        }

        var selectedAccountIdsSet: Set<String> {
            workspaceValues.selectedAccountIdsSet
        }

        var selectedAccountNames: String? {
            workspaceValues.selectedAccountOnBudgetIdNames
        }

        var selectedCategoryIds: String? {
            guard selectedCategoryIdsSet.isNotEmpty else { return nil }
            return selectedCategoryIdsSet
                .compactMap { categories[id: $0]?.id }
                .joined(separator: ",")
        }

        var selectedCategoryNames: String? {
            guard selectedCategoryIdsSet.isNotEmpty else { return nil }
            if selectedCategoryIdsSet.count == categories.count {
                return AppStrings.allCategoriesTitle
            }

            if selectedCategoryIdsSet.count > 3 {
                return AppStrings.someCategoriesName
            }

            return selectedCategoryIdsSet
                .compactMap { categories[id: $0]?.name }
                .joined(separator: ", ")
        }

        var isAccountSelected: Bool {
            selectedAccountIds != nil
        }

        var isCategoriesSelected: Bool {
            selectedCategoryIds != nil
        }
        var isRunReportDisabled: Bool {
            !isAccountSelected && !isCategoriesSelected
        }

        var fromDateFormatted: String { Date.iso8601local.string(from: fromDate) }
        var toDateFormatted: String { Date.iso8601local.string(from: toDate) }

        func isEqual(to savedReport: SavedReport) -> Bool {
            func accountIdsAreEqual(_ lhs: String, _ rhs: String) -> Bool {
                if lhs == rhs {
                    return true
                }
                let lhsSet = WorkspaceValues.makeSet(for: lhs)
                let rhsSet = WorkspaceValues.makeSet(for: rhs)
                return lhsSet == rhsSet
            }
            return savedReport.fromDate == fromDateFormatted &&
            savedReport.toDate == toDateFormatted &&
            accountIdsAreEqual(savedReport.selectedAccountIds, selectedAccountIds ?? "")
        }

        mutating func setCategories() {
            do {
                let categoriesFetchResults = try Category.fetch(isHidden: false, budgetId: budgetId)
                categories = .init(uniqueElements: categoriesFetchResults)
            } catch {
                let logger = LogFactory.create(Self.self)
                logger.error("Unable to fetch categories")
                logger.debug("\(error.toString())")
            }
        }
    }

    enum Action {
        case chartMoreInfoTapped
        case delegate(Delegate)
        case selectAccounts(PresentationAction<SelectAccountsFeature.Action>)
        case selectCategories(PresentationAction<SelectCategoriesFeature.Action>)
        case updateFromDateTapped(Date)
        case updateToDateTapped(Date)
        case setPopoverFromDate(Bool)
        case setPopoverToDate(Bool)
        case selectAccountRowTapped
        case selectCategoriesRowTapped
        case runReportTapped
        case onAppear

        @CasePathable
        enum Delegate: Equatable {
            case reportReadyToRun
        }

    }

    @Dependency(\.configProvider) var configProvider

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .chartMoreInfoTapped:
                state.showChartMoreInfo = !state.showChartMoreInfo
                return .none

            case let .setPopoverFromDate(isPresented):
                state.popoverFromDate = isPresented
                return .none

            case let .setPopoverToDate(isPresented):
                state.popoverToDate = isPresented
                return .none

            case let .updateFromDateTapped(fromDate):
                // if from date is greater than toDate, update toDate to be last day in that month
                if fromDate > state.toDate {
                    state.toDate = fromDate.lastDayInMonth()
                }
                state.fromDate = fromDate
                return .none

            case let .updateToDateTapped(toDate):
                // Ensure date ranges are valid
                let cleanedToDate = toDate < state.fromDate ? state.fromDate.lastDayInMonth() : toDate
                state.toDate = cleanedToDate
                return .none

            case .runReportTapped:
                return .send(.delegate(.reportReadyToRun), animation: .smooth)

            case .selectAccountRowTapped:
                state.selectedAccounts = .init(budgetId: state.budgetId)
                return .none

            case .selectCategoriesRowTapped:
                state.selectedCategories = .init(
                    selected: state.$selectedCategoryIdsSet,
                    budgetId: state.budgetId
                )
                return .none

            case .onAppear:
                // Ensure provided date is first day of month in FromDate
                // and last day of month ToDate
                state.fromDate = state.fromDate.firstDayInMonth()
                state.toDate = state.toDate.lastDayInMonth()
                return .none

            case .delegate, .selectAccounts, .selectCategories:
                return .none
            }
        }
        .ifLet(\.$selectedAccounts, action: \.selectAccounts) {
            SelectAccountsFeature()
        }
        .ifLet(\.$selectedCategories, action: \.selectCategories) {
            SelectCategoriesFeature()
        }
    }
}

// MARK: - Date

private extension Date {

    static var firstDayOfLastMonth: Self {
        .now.advanceMonths(by: -1, strategy: .firstDay)
    }

    static var lastDayOfThisMonth: Self {
        .now.advanceMonths(by: 0, strategy: .lastDay)
    }
}
