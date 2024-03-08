@testable import BudgetSystemService
import ConcurrencyExtras
import XCTest

final class BudgetClientTests: XCTestCase {

    var sut: BudgetClient!
    
    func testFetchBudgetSummaries() async throws {
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider)

        XCTAssertTrue(sut.budgetSummaries.isEmpty)
        await sut.updateBudgetSummaries()
        // yield a few times to allow publisher to be updated with new account values
        await Task.megaYield()

        // then
        XCTAssertEqual(sut.budgetSummaries.elements, Factory.budgetSummaries)
    }

    func testFetchAccounts() async throws {
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider, selectedBudgetId: "someBudgetId")

        XCTAssertTrue(sut.accounts.isEmpty)
        await sut.updateAccounts()
        // yield a few times to allow publisher to be updated with new account values
        await Task.megaYield()
        XCTAssertEqual(sut.accounts.elements, Factory.accounts)
    }

    func testUpdateSelectedAccountSuccess() async throws {
        // given
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider)

        await sut.updateBudgetSummaries()
        await Task.megaYield()
        XCTAssertNil(sut.selectedBudgetId)

        // when
        try sut.updateSelectedBudgetId("Budget2")

        // then
        XCTAssertEqual(sut.selectedBudgetId, "Budget2")
    }

    func testUpdateSelectedAccountThrowsError() async throws {
        // given
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider)

        await sut.updateBudgetSummaries()
        await Task.megaYield()
        XCTAssertNil(sut.selectedBudgetId)

        do {
            // when
            try sut.updateSelectedBudgetId("BudgetIdDoesNotExists")

        } catch {
            // then
            XCTAssertTrue(error is BudgetClientError)
            XCTAssertEqual(error.localizedDescription, "The selected budget is not valid or could not be found.")
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
            .init(id: "Budget1", name: "Summary One", lastModifiedOn: "Yesterday", firstMonth: "March", lastMonth: "May"),
            .init(id: "Budget2", name: "Summary Two", lastModifiedOn: "Days ago", firstMonth: "April", lastMonth: "Jun")
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
