@testable import BudgetSystemService
import ConcurrencyExtras
import MoneyCommon
import XCTest

final class BudgetClientTests: XCTestCase {

    var sut: BudgetClient!
    
    func testFetchBudgetSummaries() async throws {
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider)

        let budgetSummaries = try await sut.fetchBudgetSummaries()

        // then
        XCTAssertEqual(budgetSummaries, Factory.budgetSummaries)
        XCTAssertEqual(budgetSummaries[0].accounts, Factory.accounts)
    }

    func testFetchCategoryValues() async throws {
        // Given
        let budgetId = "Budget1"
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider, selectedBudgetId: budgetId)


        _ = try await sut.fetchBudgetSummaries()

        // when
        let result = await sut.fetchCategoryValues(budgetId: budgetId, lastServerKnowledge: nil)
        await Task.megaYield()
        XCTAssertEqual(result.group, Factory.categoryGroup)
        XCTAssertEqual(result.categories, Factory.categories)
    }

    func testUpdateSelectedAccountSuccess() async throws {
        // given
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider)

        _ = try await sut.fetchBudgetSummaries()
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

        _ = try await sut.fetchBudgetSummaries()
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

    static func createBudgetClientWithSelectBudgetId(_ budgetId: String) async throws -> BudgetClient {
        let provider = createBudgetProvider()
        let client = BudgetClient(provider: provider)

        _ = try await client.fetchBudgetSummaries()
        await Task.megaYield()
        XCTAssertNil(client.selectedBudgetId)
        try client.updateSelectedBudgetId(budgetId)

        return client
    }

    static func createBudgetProvider(
        budgetSummaries: [BudgetSummary]? = nil,
        accounts: [Account]? = nil,
        categoryValues: ([CategoryGroup],[BudgetSystemService.Category], Int)? = nil,
        transactions: [TransactionEntry]? = nil
    ) -> BudgetProvider {
        .init {
            budgetSummaries ?? Self.budgetSummaries
        } fetchCategoryValues: { params in
            categoryValues ?? (categoryGroup, categories, 100)
        } fetchTransactions: { params in
            transactions ?? Self.transactions
        } fetchAllTransactions: { _ in
            (transactions ?? Self.transactions, 0)
        }
    }

    static var budgetSummaries: [BudgetSummary] {
        [
            .init(id: "Budget1", name: "Summary One", lastModifiedOn: "Yesterday", firstMonth: "March", lastMonth: "May", currency: .AUD, accounts: accounts),
            .init(id: "Budget2", name: "Summary Two", lastModifiedOn: "Days ago", firstMonth: "April", lastMonth: "Jun", currency: .AUD, accounts: [])
        ]
    }

    static var accounts: [Account] {
        [
            .init(id: "01", budgetId: "Budget1", name: "First", onBudget: true, closed: false, deleted: false),
            .init(id: "02", budgetId: "Budget1", name: "Second", onBudget: true, closed: false, deleted: false),
            .init(id: "03", budgetId: "Budget1", name: "Third", onBudget: true, closed: false, deleted: false),
        ]
    }

    static var categoryGroup: [CategoryGroup] {
        [
            .init(id: "CG1", name: "Fixed Expenses", hidden: false, deleted: false, budgetId: "Budget1"),
            .init(id: "CG2", name: "Transportation", hidden: false, deleted: false, budgetId: "Budget1")
        ]
    }

    static var categories: [BudgetSystemService.Category] {
        [
            .init(
                id: "CAT1",
                categoryGroupId: "GC1",
                name: "Rent",
                hidden: false,
                deleted: false,
                budgetId: "Budget1"
            ),
            .init(
                id: "CAT2",
                categoryGroupId: "GC2",
                name: "Train Ticket",
                hidden: false,
                deleted: false,
                budgetId: "Budget1"
            ),
            .init(
                id: "CAT3",
                categoryGroupId: "GC2",
                name: "Taxi / Uber",
                hidden: false,
                deleted: false,
                budgetId: "Budget1"
            )
        ]
    }

    static var transactions: [TransactionEntry] {
        [
            .init(
                id: "T1",
                budgetId: "Budget1",
                date: Date.iso8601utc.date(from: "2024-02-01")!,
                rawAmount: -100,
                currencyCode: Currency.AUD.code,
                payeeName: "Coles",
                accountId: "A1",
                accountName: "Account First",
                categoryId: "C1",
                categoryName: "Groceries",
                transferAccountId: nil,
                deleted: false
            ),
            .init(
                id: "T2",
                budgetId: "Budget1",
                date: Date.iso8601utc.date(from: "2024-03-04")!,
                rawAmount: -12345,
                currencyCode: Currency.AUD.code,
                payeeName: "Engerix",
                accountId: "A1",
                accountName: "Account First",
                categoryId: "C2",
                categoryName: "Electricity Bill",
                transferAccountId: nil,
                deleted: false
            ),
            .init(
                id: "T3",
                budgetId: "Budget1",
                date: Date.iso8601utc.date(from: "2024-04-05")!,
                rawAmount: -29999,
                currencyCode: Currency.AUD.code,
                payeeName: "Landlord",
                accountId: "A2",
                accountName: "Account Second",
                categoryId: "C3",
                categoryName: "Rent",
                transferAccountId: nil,
                deleted: false
            )
        ]
    }
}
