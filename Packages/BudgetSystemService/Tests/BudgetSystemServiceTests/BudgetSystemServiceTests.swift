@testable import BudgetSystemService
import ConcurrencyExtras
import XCTest

final class BudgetSystemServiceTests: XCTestCase {

    var sut: BudgetClient!
    
    func testFetchAccounts() async throws {
        await withMainSerialExecutor {
            let budgetProvider = Factory.createBudgetProvider()
            sut = BudgetClient(provider: budgetProvider, selectedBudgetId: "someBudgetId")
            
            XCTAssertTrue(sut.accounts.isEmpty)
            sut.fetchAccounts()
            // yield a few times to allow publisher to be updated with new account values
            await Task.megaYield()
            XCTAssertEqual(sut.accounts.elements, Factory.accounts)
        }
    }
}

private enum Factory {
    
    static func createBudgetProvider() -> BudgetProvider {
        .init { budgetId in
            Self.accounts  // return stubbed data
        }
    }
    
    static var accounts: [Account] {
        [
            .init(id: "01", name: "First"),
            .init(id: "02", name: "Second"),
            .init(id: "03", name: "Third"),
        ]
    }
}
