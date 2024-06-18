import Combine
import Foundation
import IdentifiedCollections
import OSLog

public actor BudgetClient {

    public private(set) var provider: BudgetProvider

    public var budgetSummaries: [BudgetSummary] { _budgetSummaries }
    private var _budgetSummaries: [BudgetSummary] = []

    public let authorizationStatusStream: AsyncStream<AuthorizationStatus>
    private let authorizationStatusStreamCont: AsyncStream<AuthorizationStatus>.Continuation
    private var _authorizationStatus: AuthorizationStatus = .unknown

    private let logger = Logger(subsystem: "BudgetSystemService", category: "BudgetClient")

    public init(
        provider: BudgetProvider,
        budgetSummaries: [BudgetSummary] = [],
        authorizationStatus: AuthorizationStatus = .unknown
    ) {
        self.provider = provider
        self._budgetSummaries = budgetSummaries
        self._authorizationStatus = authorizationStatus
        let (authStream, authCont) = AsyncStream.makeStream(of: AuthorizationStatus.self)
        self.authorizationStatusStream = authStream
        self.authorizationStatusStreamCont = authCont
    }

    public var isAuthenticated: Bool {
        _authorizationStatus == .loggedIn
    }

    public func updateProvider(_ provider: BudgetProvider) {
        self.provider = provider
    }

    public func fetchBudgetSummaries() async throws -> [BudgetSummary] {
        do {
            logger.debug("fetching budget summaries ...")
            let budgetSummaries = try await provider.fetchBudgetSummaries()
            logger.debug("budgetSummaries count(\(budgetSummaries.count))")
            self.setBudgetSummaries(to: budgetSummaries)
            self.setAuthorization(to: .loggedIn)
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
        guard let currency = budgetSummaries.first(where: { $0.id == budgetId })?.currency
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
            self.setAuthorization(to: .loggedOut)
            logger.error("Budget Client is not authorized, status updated to logged out")
            return
        }
        logger.error("\(error.localizedDescription)")
    }

    func setBudgetSummaries(to summaries: [BudgetSummary]) {
        _budgetSummaries = summaries
    }

    public func setAuthorization(to newStatus: AuthorizationStatus) {
        _authorizationStatus = newStatus
        authorizationStatusStreamCont.yield(newStatus)
    }

    deinit {
        authorizationStatusStreamCont.finish()
    }
}

// MARK: - Initializer for Previews

extension BudgetClient {
    
    /// Only for Preview Usage. Sets the published properties with their values for previews
    public init(
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
        self.init(provider: provider, budgetSummaries: budgetSummaries.elements, authorizationStatus: authorizationStatus)
    }
}

// MARK: - Static BudgetClient instances

extension BudgetClient {
    
    public static let notAuthorizedClient = BudgetClient(provider: .notAuthorized, authorizationStatus: .loggedOut)
}
