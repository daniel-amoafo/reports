import Combine
import Foundation
import IdentifiedCollections
import OSLog

@MainActor
public class BudgetClient {

    public private(set) var provider: BudgetProvider

    @Published public private(set) var budgetSummaries: IdentifiedArrayOf<BudgetSummary> = []
    @Published public private(set) var accounts: IdentifiedArrayOf<Account> = []
    @Published public var authorizationStatus: AuthorizationStatus
    @Published public private(set) var selectedBudgetId: String?

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
        guard selectedId != selectedBudgetId else {
            logger.debug("Selected budgetId is already set to: \(selectedId). No action taken.")
            return
        }
        selectedBudgetId = selectedId
        logger.debug("BudgetClient selectedBudgetId updated to: \(selectedId)")
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

    @discardableResult
    public func fetchCategoryValues(budgetId: String, lastServerKnowledge: Int?) async
    -> (group: [CategoryGroup], categories: [Category], serverKnowledge: Int) {
        logger.debug("fetching category values ...")
        guard isAuthenticated else { return ([], [], 0) }
        do {
            let result = try await provider.fetchCategoryValues(
                .init(budgetId: budgetId, lastServerKnowledge: lastServerKnowledge)
            )
            return (result.0, result.1, result.2)
        } catch {
            logoutIfNeeded(error)
            return ([], [], 0)
        }
    }

    public func fetchAllTransactions(budgetId: String, lastServerKnowledge: Int?)
    async throws -> ([TransactionEntry], serverKnowledge: Int) {
        guard let currency = budgetSummaries[id: budgetId]?.currency
        else { return ([], 0) }
        logger.debug("fetching all transaction entries...")
        return try await provider.fetchAllTransactions(
            .init(
                budgetId: budgetId,
                startDate: nil,
                finishDate: nil,
                currency: currency,
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
            (categoryGroups.elements, categories.elements, 0)
        } fetchTransactions: { _ in
            transactions.elements
        } fetchAllTransactions: { _ in
            (transactions.elements, 0)
        }
        self.init(provider: provider)

        // set the published values so previews work and not dependent on async routines
        self.budgetSummaries = budgetSummaries
        self.accounts = accounts
        self.authorizationStatus = authorizationStatus
        self.selectedBudgetId = selectedBudgetId
    }
}

// MARK: - Static BudgetClient instances

extension BudgetClient {
    
    public static let notAuthorizedClient = BudgetClient(provider: .notAuthorized, authorizationStatus: .loggedOut)
}
