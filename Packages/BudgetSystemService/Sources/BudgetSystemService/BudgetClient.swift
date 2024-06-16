import Combine
import Foundation
import IdentifiedCollections
import OSLog

@MainActor
public final class BudgetClient {

    public private(set) var provider: BudgetProvider

    @Published public private(set) var budgetSummaries: IdentifiedArrayOf<BudgetSummary> = []
    @Published public var authorizationStatus: AuthorizationStatus = .unknown

    private let logger = Logger(subsystem: "BudgetSystemService", category: "BudgetClient")

    public init(
        provider: BudgetProvider,
        budgetSummaries: IdentifiedArrayOf<BudgetSummary> = [],
        authorizationStatus: AuthorizationStatus = .unknown
    ) {
        self.provider = provider
        self.budgetSummaries = budgetSummaries
        self.authorizationStatus = authorizationStatus
    }

    public var isAuthenticated: Bool {
        authorizationStatus == .loggedIn
    }

    public func updateProvider(_ provider: BudgetProvider) {
        self.provider = provider
    }

    public func fetchBudgetSummaries() async throws -> [BudgetSummary] {
        do {
            logger.debug("fetching budget summaries ...")
            let budgetSummaries = try await provider.fetchBudgetSummaries()
            logger.debug("budgetSummaries count(\(budgetSummaries.count))")
            self.budgetSummaries = IdentifiedArray(uniqueElements: budgetSummaries)
            self.authorizationStatus = .loggedIn
            return budgetSummaries
        } catch {
            await logoutIfNeeded(error)
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
            await logoutIfNeeded(error)
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

    func logoutIfNeeded(_ error: Error) async {
        if let budgetClientError = error as? BudgetClientError,
           budgetClientError.isNotAuthorized {
            self.authorizationStatus = .loggedOut
            logger.error("Budget Client is not authorized, status updated to logged out")
            return
        }
        logger.error("\(error.localizedDescription)")
    }

}

// MARK: - Initializer for Previews

extension BudgetClient {
    
    /// Only for Preview Usage. Sets the published properties with their values for previews
    public convenience init(
        budgetSummaries: IdentifiedArrayOf<BudgetSummary>,
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
        // set the published values so previews work and not dependent on async routines
        self.init(provider: provider, budgetSummaries: budgetSummaries, authorizationStatus: authorizationStatus)
    }
}

// MARK: - Static BudgetClient instances

extension BudgetClient {
    
    public static let notAuthorizedClient = BudgetClient(provider: .notAuthorized, authorizationStatus: .loggedOut)
}
