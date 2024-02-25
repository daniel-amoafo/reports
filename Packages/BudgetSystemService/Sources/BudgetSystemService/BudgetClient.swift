import Combine
import Foundation
import IdentifiedCollections
import OSLog

public class BudgetClient {
    
    public private(set) var provider: BudgetProvider
    public private(set) var selectedBudgetId: String?

    @Published public private(set) var bugetSummaries: IdentifiedArrayOf<BudgetSummary> = []
    @Published public private(set) var accounts: IdentifiedArrayOf<Account> = []
    @Published public var authorizationStatus: AuthorizationStatus

    private let logger = Logger(subsystem: "BudgetSystemService", category: "BudgetClient")

    public init(provider: BudgetProvider, selectedBudgetId: String? = nil, authorizationStatus: AuthorizationStatus = .unknown) {
        self.provider = provider
        self.selectedBudgetId = selectedBudgetId
        self.authorizationStatus = authorizationStatus
    }

    public func updateProvider(_ provider: BudgetProvider) {
        self.provider = provider
    }

    public func updateBudgetSummaries() async {
        do {
            let fetchedBudgetSummaries = try await provider.fetchBudgetSummaries()
            Task {
                await MainActor.run {
                    // updating published events on main run loop
                    self.bugetSummaries = IdentifiedArray(uniqueElements: fetchedBudgetSummaries)
                    if let selectedBudgetId = self.selectedBudgetId,
                        !fetchedBudgetSummaries.map(\.id).contains(selectedBudgetId) {
                        self.selectedBudgetId = nil
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
        } else {
            logger.error("\(error.localizedDescription)")
        }
    }
}

// MARK: - Static BudgetClient instances

extension BudgetClient {
    
    public static let noActiveClient = BudgetClient(provider: .noop, authorizationStatus: .loggedOut)
}

// MARK: - BudgetProvider

public struct BudgetProvider {
    
    private let _fetchBudgetSummaries: () async throws -> [BudgetSummary]
    private let _fetchAccounts: (_ budgetId: String) async throws -> [Account]
    
    public init(
        fetchBudgetSummaries: @Sendable @escaping () async throws -> [BudgetSummary],
        fetchAccounts: @Sendable @escaping (_ budgetId: String) async throws -> [Account]
    ) {
        self._fetchBudgetSummaries = fetchBudgetSummaries
        self._fetchAccounts = fetchAccounts
    }
    
}

public extension BudgetProvider {
    
    func fetchBudgetSummaries() async throws -> [BudgetSummary] {
        try await _fetchBudgetSummaries()
    }

    func fetchAccounts(for budgetId: String) async throws -> [Account] {
        try await _fetchAccounts(budgetId)
    }
}

extension BudgetProvider {

    // Static BudgetProvider that does nothing
    static let noop = BudgetProvider(
        fetchBudgetSummaries: { return [] },
        fetchAccounts: { _ in return [] }
    )
}

// MARK: - BudgetClientError

public enum BudgetClientError: LocalizedError {

    case http(code: String, message: String?)
    case unknown

    public var errorDescription: String? {
        switch self {
        case let .http(_, message):
            return message
        case .unknown:
            return nil
        }
    }

    public var code: String? {
        switch self {
        case let .http(code, _):
            return code
        case .unknown:
            return nil
        }
    }

    var isNotAuthorized: Bool {
        if let code = self.code, code == "401" {
            return true
        }
        return false
    }
}
