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
                    await fetchBudgetSummaryValues()
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
        Task {
            await fetchBudgetSummaries()
        }
    }

    public func updateSelectedBudgetId(_ selectedId: String) throws {
        guard budgetSummaries.map(\.id).contains(selectedId) else {
            throw BudgetClientError.selectedBudgetIdInvalid
        }
        selectedBudgetId = selectedId
        logger.debug("BudgetClient selectedBudgetId updated to: \(selectedId)")
    }

    /// Helper function to fetch published data values
    public func fetchLoadedData() async {
        await fetchBudgetSummaries()
        await fetchBudgetSummaryValues()
    }

    func fetchBudgetSummaryValues() async {
        await fetchAccounts()
        await fetchCategoryValues()
    }

    public func fetchBudgetSummaries() async {
        do {
            let fetchedBudgetSummaries = try await provider.fetchBudgetSummaries()
            Task {
                await MainActor.run {
                    // updating published events on main run loop
                    self.budgetSummaries = IdentifiedArray(uniqueElements: fetchedBudgetSummaries)
                    // must be logged in to successfully fetch budgetsummaries without error
                    self.authorizationStatus = .loggedIn

                    logger.debug("budgetSummaries count(\(self.budgetSummaries.count))")
                    // If set, ensure the selected budget id is in the updated budget summaries
                    if let selectedBudgetId = self.selectedBudgetId,
                        !fetchedBudgetSummaries.map(\.id).contains(selectedBudgetId) {
                        self.selectedBudgetId = nil
                        logger.debug("selectedBudgetId set to nil")
                    }
                }
            }
        } catch {
            await resolveError(error)
        }
    }

    /// Fetches account list from budget provider and publishes accounts
    @discardableResult
    public func fetchAccounts() async -> IdentifiedArrayOf<Account> {
        guard let selectedBudgetId, isAuthenticated else { return [] }
        do {
            let fetchedAccounts = try await provider.fetchAccounts(selectedBudgetId)
            let accounts = IdentifiedArray(uniqueElements: fetchedAccounts)
                .filter { $0.deleted == false }
            Task { @MainActor in
                self.accounts = accounts
            }
            logger.debug("accounts count (\(accounts.count))")
            return accounts
        } catch {
            await resolveError(error)
            return []
        }
    }

    public func fetchCategoryValues() async {
        guard let selectedBudgetId, isAuthenticated,
              let currency = budgetSummaries[id: selectedBudgetId]?.currency else { return }
        do {
            let fetchedCategoryValues = try await provider.fetchCategoryValues(
                .init(budgetId: selectedBudgetId, currency: currency)
            )
            let categoryGroups = IdentifiedArray(uniqueElements: fetchedCategoryValues.groups)
            let categories = IdentifiedArray(uniqueElements: fetchedCategoryValues.categories)
            Task { @MainActor in
                self.categoryGroups = categoryGroups
                self.categories = categories
            }
            logger.debug("categoryGroups count (\(categoryGroups.count))")
            logger.debug("categories count (\(categories.count))")
        } catch {
            await resolveError(error)
        }
    }

    /// Fetch transactions from the selected Budget with a given start date
    public func fetchTransactions(
        startDate: Date,
        finishDate: Date,
        filterBy: BudgetProvider.TransactionParameters.FilterByOption? = nil
    ) async throws -> IdentifiedArrayOf<TransactionEntry> {
        guard let selectedBudgetId, let currency = budgetSummaries[id: selectedBudgetId]?.currency else { return [] }
        do {
            let fetchedTransactions = try await provider.fetchTransactions(
                .init(
                    budgetId: selectedBudgetId,
                    startDate: startDate,
                    finishDate: finishDate,
                    currency: currency,
                    categoryGroupProvider: self,
                    filterBy: filterBy
                )
            )
                .filter {
                    (startDate...finishDate).contains($0.date) &&
                    $0.categoryGroupName != "Internal Master Category" &&
                    $0.transferAccountId == nil &&
                    $0.deleted == false
                }
            return IdentifiedArray(uniqueElements: fetchedTransactions)
        } catch {
            await resolveError(error)
            throw error
        }
    }

    @MainActor
    func resolveError(_ error: Error) {
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
        } fetchAccounts: { budgetId in
            accounts.elements
        } fetchCategoryValues: { _ in
            (categoryGroups.elements, categories.elements)
        } fetchTransactions: { _ in
            transactions.elements
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

