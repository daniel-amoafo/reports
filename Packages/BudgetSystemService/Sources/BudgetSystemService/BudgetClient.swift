import Combine
import Foundation
import IdentifiedCollections
import OSLog

public class BudgetClient {
    
    public private(set) var provider: BudgetProvider

    @Published public private(set) var budgetSummaries: IdentifiedArrayOf<BudgetSummary> = []
    @Published public private(set) var accounts: IdentifiedArrayOf<Account> = []
    @Published public var authorizationStatus: AuthorizationStatus
    @Published public private(set) var selectedBudgetId: String? {
        didSet {
            if oldValue != selectedBudgetId {
                Task {
                    await fetchAccounts()
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

    public func fetchBudgetSummaries() async {
        do {
            let fetchedBudgetSummaries = try await provider.fetchBudgetSummaries()
            Task {
                await MainActor.run {
                    // updating published events on main run loop
                    self.budgetSummaries = IdentifiedArray(uniqueElements: fetchedBudgetSummaries)
                    // must be logged in to successfully fetch budgetsummaries without error
                    self.authorizationStatus = .loggedIn

                    logger.debug("budgetSummaries updated count(\(self.budgetSummaries.count))")
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
        guard let selectedBudgetId else { return [] }
        do {
            let fetchedAccounts = try await provider.fetchAccounts(for: selectedBudgetId)
            let accounts = IdentifiedArray(uniqueElements: fetchedAccounts)
            Task { @MainActor in
                self.accounts = accounts
            }
            logger.debug("accounts updated count - (\(accounts.count))")
            return accounts
        } catch {
            await resolveError(error)
            return []
        }
    }

    /// Fetch transactions from the selected Budget with a given start date
    public func fetchTransactionsAll(startDate: Date) async throws -> IdentifiedArrayOf<Transaction> {
        guard let selectedBudgetId, let currency = budgetSummaries[id: selectedBudgetId]?.currency else { return [] }
        do {
            let fetchedTransactions = try await provider.fetchTransactionsAll(selectedBudgetId, startDate, currency)
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
        }
        logger.error("\(error.localizedDescription)")
    }
}

// MARK: - Static BudgetClient instances

extension BudgetClient {
    
    public static let notAuthorizedClient = BudgetClient(provider: .notAuthorized, authorizationStatus: .loggedOut)
}
