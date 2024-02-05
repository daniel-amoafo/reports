import Combine
import IdentifiedCollections

public class BudgetSystemService {
    
    public let provider: BudgetProvider
    private(set) var selectedBudgetId: String?
    
    @Published private(set) var accounts: IdentifiedArrayOf<Account> = []
    
    public init(provider: BudgetProvider, selectedBudgetId: String? = nil) {
        self.provider = provider
        self.selectedBudgetId = selectedBudgetId
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

public struct BudgetProvider {
    
    private let _fetchAccounts: (_ budgetId: String) async throws -> [Account]
    
    internal init(
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
