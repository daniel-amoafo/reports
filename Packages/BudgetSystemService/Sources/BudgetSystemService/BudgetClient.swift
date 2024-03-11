import Combine
import Foundation
import IdentifiedCollections
import OSLog

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

    public func updateProvider(_ provider: BudgetProvider) {
        self.provider = provider
        Task {
            await updateBudgetSummaries()
        }
    }

    public func updateSelectedBudgetId(_ selectedId: String) throws {
        guard budgetSummaries.map(\.id).contains(selectedId) else {
            throw BudgetClientError.selectedBudgetIdInvalid
        }
        selectedBudgetId = selectedId
        logger.debug("BudgetClient selectedBudgetId updated to: \(selectedId)")
    }

    public func updateBudgetSummaries() async {
        do {
            let fetchedBudgetSummaries = try await provider.fetchBudgetSummaries()
            Task {
                await MainActor.run {
                    // updating published events on main run loop
                    self.budgetSummaries = IdentifiedArray(uniqueElements: fetchedBudgetSummaries)
                    // must be logged in to successfully fetch budgetsummaries without error
                    self.authorizationStatus = .loggedIn

                    logger.debug("budgetSummaries updated count(\(self.budgetSummaries.count))")
                    // ensure the selected budget id is in the updated budget summaries
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
    public func updateAccounts() async {
        guard let selectedBudgetId else { return }
        do {
            let fetchedAccounts = try await provider.fetchAccounts(for: selectedBudgetId)
            Task {
                await MainActor.run {
                    // updating published events on main run loop
                    self.accounts = IdentifiedArray(uniqueElements: fetchedAccounts)
                }
            }
        } catch {
            await resolveError(error)
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
    
    public static let noActiveClient = BudgetClient(provider: .noop, authorizationStatus: .loggedOut)
}
