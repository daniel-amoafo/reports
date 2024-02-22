import Combine
import IdentifiedCollections

public class BudgetClient {
    
    public private(set) var provider: BudgetProvider
    public private(set) var selectedBudgetId: String?

    @Published public private(set) var accounts: IdentifiedArrayOf<Account> = []
    @Published public private(set) var authorizationStatus: AuthorizationStatus

    public init(provider: BudgetProvider, selectedBudgetId: String? = nil, authorizationStatus: AuthorizationStatus = .unknown) {
        self.provider = provider
        self.selectedBudgetId = selectedBudgetId
        self.authorizationStatus = authorizationStatus
    }

    public func updateProvider(_ provider: BudgetProvider) {
        self.provider = provider
    }

    public func fetchAccounts() {
        guard let selectedBudgetId else { return }
        Task {
            do {
                let result = try await provider.fetchAccounts(for: selectedBudgetId)
                await MainActor.run {
                    // updating published events should be run on main
                    accounts = IdentifiedArray(uniqueElements: result)
                }
            } catch {
                fatalError("\(#function): unexpected error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Static BudgetClient instances

extension BudgetClient {
    
    public static let noActiveClient = BudgetClient(provider: .noop, authorizationStatus: .logggedOut)
}

// MARK: -

public struct BudgetProvider {
    
    private let _fetchAccounts: (_ budgetId: String) async throws -> [Account]
    
    public init(
        fetchAccounts: @escaping (_ budgetId: String) async throws -> [Account]
    ) {
        self._fetchAccounts = fetchAccounts
    }
    
}

public extension BudgetProvider {
    
    func fetchAccounts(for budgetId: String) async throws -> [Account] {
        try await _fetchAccounts(budgetId)
    }
}


extension BudgetProvider {

    // Static BudgetProvider that does nothing
    static let noop = BudgetProvider(fetchAccounts: { budgetId in return [] })
}
