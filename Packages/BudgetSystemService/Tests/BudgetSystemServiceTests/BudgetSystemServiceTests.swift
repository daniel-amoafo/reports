@testable import BudgetSystemService
import ConcurrencyExtras
import XCTest

final class BudgetSystemServiceTests: XCTestCase {

    var sut: BudgetClient!
    
    func testFetchBudgetSummaries() async throws {
        await withMainSerialExecutor {
            let budgetProvider = Factory.createBudgetProvider()
            sut = BudgetClient(provider: budgetProvider)

            XCTAssertTrue(sut.bugetSummaries.isEmpty)
            await sut.updateBudgetSummaries()
            await Task.megaYield()
            XCTAssertEqual(sut.bugetSummaries.elements, Factory.budgetSummaries)
        }
    }

    func testFetchAccounts() async throws {
        await withMainSerialExecutor {
            let budgetProvider = Factory.createBudgetProvider()
            sut = BudgetClient(provider: budgetProvider, selectedBudgetId: "someBudgetId")
            
            XCTAssertTrue(sut.accounts.isEmpty)
            await sut.updateAccounts()
            // yield a few times to allow publisher to be updated with new account values
            await Task.megaYield()
            XCTAssertEqual(sut.accounts.elements, Factory.accounts)
        }
    }
}

private enum Factory {
    
    static func createBudgetProvider() -> BudgetProvider {
        .init {
            Self.budgetSummaries
        } fetchAccounts: { budgetId in
            Self.accounts
        }
    }

    static var budgetSummaries: [BudgetSummary] {
        [
            .init(id: "1", name: "Summary One", lastModifiedOn: "Yesterday", firstMonth: "March", lastMonth: "May"),
            .init(id: "2", name: "Summary Two", lastModifiedOn: "Days ago", firstMonth: "April", lastMonth: "Jun")
        ]
    }

    static var accounts: [Account] {
        [
            .init(id: "01", name: "First"),
            .init(id: "02", name: "Second"),
            .init(id: "03", name: "Third"),
        ]
    }
}
