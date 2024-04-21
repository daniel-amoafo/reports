@testable import BudgetSystemService
import ConcurrencyExtras
import MoneyCommon
import XCTest

final class BudgetClientTests: XCTestCase {

    var sut: BudgetClient!
    
    func testFetchBudgetSummaries() async throws {
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider)

        XCTAssertTrue(sut.budgetSummaries.isEmpty)
        await sut.fetchBudgetSummaries()
        // yield a few times to allow publisher to be updated with new account values
        await Task.megaYield()

        // then
        XCTAssertEqual(sut.budgetSummaries.elements, Factory.budgetSummaries)
    }

    func testFetchAccounts() async throws {
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider, selectedBudgetId: "someBudgetId")

        XCTAssertTrue(sut.accounts.isEmpty)
        await sut.fetchAccounts()
        // yield a few times to allow publisher to be updated with new account values
        await Task.megaYield()
        XCTAssertEqual(sut.accounts.elements, Factory.accounts)
    }

    func testUpdateSelectedAccountSuccess() async throws {
        // given
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider)

        await sut.fetchBudgetSummaries()
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

        await sut.fetchBudgetSummaries()
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

    func testFetchTransactionsAll() async throws {
        // given
        sut = try await Factory.createBudgetClientWithSelectBudgetId("Budget1")
        let startDate = iso8601DateFormatter.date(from: "2024-02-01")!

        // when
        let transactions = await sut.fetchTransactionsAll(startDate: startDate)
        await Task.megaYield()

        // then
        XCTAssertEqual(transactions.count, 3)
    }
}

private enum Factory {

    static func createBudgetClientWithSelectBudgetId(_ budgetId: String) async throws -> BudgetClient {
        let provider = createBudgetProvider()
        let client = BudgetClient(provider: provider)

        await client.fetchBudgetSummaries()
        await Task.megaYield()
        XCTAssertNil(client.selectedBudgetId)
        try client.updateSelectedBudgetId("Budget1")

        return client
    }

    static func createBudgetProvider(
        budgetSummaries: [BudgetSummary]? = nil,
        accounts: [Account]? = nil,
        transactions: [Transaction]? = nil
    ) -> BudgetProvider {
        .init {
            budgetSummaries ?? Self.budgetSummaries
        } fetchAccounts: { budgetId in
            accounts ?? Self.accounts
        } fetchTransactionsAll: { budgetId, startDate, currency in
            transactions ?? Self.transactions
        }
    }

    static var budgetSummaries: [BudgetSummary] {
        [
            .init(id: "Budget1", name: "Summary One", lastModifiedOn: "Yesterday", firstMonth: "March", lastMonth: "May", currency: .AUD),
            .init(id: "Budget2", name: "Summary Two", lastModifiedOn: "Days ago", firstMonth: "April", lastMonth: "Jun", currency: .AUD)
        ]
    }

    static var accounts: [Account] {
        [
            .init(id: "01", name: "First"),
            .init(id: "02", name: "Second"),
            .init(id: "03", name: "Third"),
        ]
    }

    static var transactions: [Transaction] {
        [
            .init(
                id: "T1",
                date: iso8601DateFormatter.date(from: "2024-02-01")!,
                money: Money(Decimal(-100), currency: .AUD),
                accountId: "A1",
                accountName: "Account First",
                categoryId: "C1",
                categoryName: "Groceries"
            ),
            .init(
                id: "T2",
                date: iso8601DateFormatter.date(from: "2024-03-04")!,
                money: Money(Decimal(-123.45), currency: .AUD),
                accountId: "A1",
                accountName: "Account First",
                categoryId: "C2",
                categoryName: "Electricity Bill"
            ),
            .init(
                id: "T3",
                date: iso8601DateFormatter.date(from: "2024-04-05")!,
                money: Money(Decimal(-299.99), currency: .AUD),
                accountId: "A2",
                accountName: "Account Second",
                categoryId: "C3",
                categoryName: "Rent"
            )
        ]
    }
}

private var iso8601DateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = NSTimeZone.local
    return formatter
}()
