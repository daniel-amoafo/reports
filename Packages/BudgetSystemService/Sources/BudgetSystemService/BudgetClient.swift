import Combine
import Foundation
import IdentifiedCollections
import OSLog

public class BudgetClient {
    
    public private(set) var provider: BudgetProvider

    @Published public private(set) var budgetSummaries: IdentifiedArrayOf<BudgetSummary> = []
    @Published public private(set) var accounts: IdentifiedArrayOf<Account> = []
    @Published public private(set) var categoryGroups: IdentifiedArrayOf<CategoryGroup> = []
    @Published public private(set) var categories: IdentifiedArrayOf<Category> = []
    @Published public var authorizationStatus: AuthorizationStatus
    @Published public private(set) var selectedBudgetId: String? {
        didSet {
            if oldValue != selectedBudgetId {
                Task {
                    await fetchAccountAndCategoryValues()
                }
            }
        }
    }

    private let logger = Logger(subsystem: "BudgetSystemService", category: "BudgetClient")

    public init(
        provider: BudgetProvider,
        selectedBudgetId: String? = nil,
        authorizationStatus: AuthorizationStatus = .unknown
    ) {
        self.provider = provider
        self.selectedBudgetId = selectedBudgetId
        self.authorizationStatus = authorizationStatus

    }

    public var isAuthenticated: Bool {
        authorizationStatus == .loggedIn
    }

    public var selectedBudget: BudgetSummary? {
        guard let selectedBudgetId else { return nil }
        return budgetSummaries[id: selectedBudgetId]
    }

    public func updateProvider(_ provider: BudgetProvider) {
        self.provider = provider
    }

    public func updateSelectedBudgetId(_ selectedId: String) throws {
        guard budgetSummaries.map(\.id).contains(selectedId) else {
            throw BudgetClientError.selectedBudgetIdInvalid
        }
        selectedBudgetId = selectedId
        logger.debug("BudgetClient selectedBudgetId updated to: \(selectedId)")
    }


    func fetchAccountAndCategoryValues() async {
        await fetchCategoryValues()
    }

    public func fetchBudgetSummaries() async throws -> [BudgetSummary] {
        do {
            logger.debug("fetching budget summaries ...")
            let budgetSummaries = try await provider.fetchBudgetSummaries()
            logger.debug("budgetSummaries count(\(budgetSummaries.count))")
            await Task { @MainActor in
                self.budgetSummaries = IdentifiedArray(uniqueElements: budgetSummaries)
                self.authorizationStatus = .loggedIn
                // If set, ensure the selected budget id is in the updated budget summaries
                if let selectedBudgetId = self.selectedBudgetId,
                   !budgetSummaries.map(\.id).contains(selectedBudgetId) {
                    self.selectedBudgetId = nil
                    logger.debug("selectedBudgetId set to nil")
                }
            }.value
            return budgetSummaries
        } catch {
            logoutIfNeeded(error)
            throw error
        }
    }


    public func fetchCategoryValues() async {
        logger.debug("fetching category values ...")
        guard let selectedBudgetId, isAuthenticated,
              let currency = budgetSummaries[id: selectedBudgetId]?.currency else { return }
        do {
            let fetchedCategoryValues = try await provider.fetchCategoryValues(
                .init(budgetId: selectedBudgetId, currency: currency)
            )
            let categoryGroups = IdentifiedArray(uniqueElements: fetchedCategoryValues.groups)
            let categories = IdentifiedArray(uniqueElements: fetchedCategoryValues.categories)
            logger.debug("categoryGroups count (\(categoryGroups.count))")
            logger.debug("categories count (\(categories.count))")
            await Task { @MainActor in
                self.categoryGroups = categoryGroups
                self.categories = categories
            }.value
        } catch {
            logoutIfNeeded(error)
        }
    }

    /// Fetch transactions from the selected Budget with a given start & end date.
    /// Optional filter parameters can be provided to further constrain the fetched transactions.
    public func fetchTransactions(
        startDate: Date? = nil,
        finishDate: Date? = nil,
        filterBy: BudgetProvider.TransactionParameters.FilterByOption? = nil
    ) async throws -> IdentifiedArrayOf<TransactionEntry> {
        logger.debug("fetching transactions ...")
        guard let selectedBudgetId, let currency = budgetSummaries[id: selectedBudgetId]?.currency else { return [] }
        do {
            let fetchedTransactions = try await provider.fetchTransactions(
                .init(
                    budgetId: selectedBudgetId,
                    startDate: startDate,
                    finishDate: finishDate,
                    currency: currency,
                    categoryGroupProvider: self,
                    filterBy: filterBy,
                    lastServerKnowledge: nil
                )
            )
                .filter {
                    // Move filter criteria. Should be provided as an argument
                    let isOnBudgetAccount: Bool
                    if let account = accounts[id: $0.accountId] {
                        isOnBudgetAccount = account.onBudget
                    } else {
                        isOnBudgetAccount = false
                    }
                    let sDate = startDate ?? Date.distantPast
                    let fDate = finishDate ?? Date.distantFuture
                    return (sDate...fDate).contains($0.date) &&
                    $0.categoryGroupName != "Internal Master Category" &&
                    $0.transferAccountId == nil &&
                    $0.deleted == false &&
                    isOnBudgetAccount
                }
            return IdentifiedArray(uniqueElements: fetchedTransactions)
        } catch {
            logoutIfNeeded(error)
            throw error
        }

    }

    public func fetchAllTransactions(lastServerKnowledge: Int?)
    async throws -> ([TransactionEntry], serverKnowledge: Int) {
        guard let selectedBudgetId, let currency = budgetSummaries[id: selectedBudgetId]?.currency
        else { return ([], 0) }
        logger.debug("fetching all transaction entries...")
        return try await provider.fetchAllTransactions(
            .init(
                budgetId: selectedBudgetId,
                startDate: nil,
                finishDate: nil,
                currency: currency,
                categoryGroupProvider: self,
                filterBy: nil,
                lastServerKnowledge: lastServerKnowledge
            )
        )
    }

    func logoutIfNeeded(_ error: Error) {
        if let budgetClientError = error as? BudgetClientError,
           budgetClientError.isNotAuthorized {
            self.authorizationStatus = .loggedOut
            logger.error("Budget Client is not authorized, status updated to logged out")
            return
        }
        logger.error("\(error.localizedDescription)")
    }

}

// MARK: - Previews Initializer

extension BudgetClient {
    
    /// Only for Preview Usage. Sets the published properties with their values for previews
    public convenience init(
        budgetSummaries: IdentifiedArrayOf<BudgetSummary>,
        accounts: IdentifiedArrayOf<Account>,
        categoryGroups: IdentifiedArrayOf<CategoryGroup>,
        categories: IdentifiedArrayOf<Category>,
        transactions: IdentifiedArrayOf<TransactionEntry>,
        authorizationStatus: AuthorizationStatus,
        selectedBudgetId: String?
    ) {
        let provider = BudgetProvider {
            budgetSummaries.elements
        } fetchCategoryValues: { _ in
            (categoryGroups.elements, categories.elements)
        } fetchTransactions: { _ in
            transactions.elements
        } fetchAllTransactions: { _ in
            (transactions.elements, 0)
        }
        self.init(provider: provider)

        // set the published values so previews work and not dependent on async routines
        self.budgetSummaries = budgetSummaries
        self.accounts = accounts
        self.categoryGroups = categoryGroups
        self.categories = categories
        self.authorizationStatus = authorizationStatus
        self.selectedBudgetId = selectedBudgetId
    }
}

// MARK: - Static BudgetClient instances

extension BudgetClient {
    
    public static let notAuthorizedClient = BudgetClient(provider: .notAuthorized, authorizationStatus: .loggedOut)
}

// MARK: - CategoryGroupLookupProviding

public protocol CategoryGroupLookupProviding {
    
    func getCategoryGroupForCategory(categoryId: String?) -> CategoryGroup?
    func getCategoryGroup(groupId: String?) -> CategoryGroup?

}

extension BudgetClient: CategoryGroupLookupProviding {

    public func getCategoryGroupForCategory(categoryId: String?) -> CategoryGroup? {
        guard let categoryId, !categories.isEmpty,
              let category = categories[id: categoryId] else {
            return nil
        }
        return categoryGroups[id: category.categoryGroupId]
    }

    public func getCategoryGroup(groupId: String?) -> CategoryGroup? {
        guard let groupId, !categoryGroups.isEmpty,
              let group = categoryGroups[id: groupId] else {
            return nil
        }
        return group
    }
}

