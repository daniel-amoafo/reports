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
        sut = BudgetClient(provider: budgetProvider, selectedBudgetId: "Budget2")
        sut.authorizationStatus = .loggedIn

        XCTAssertTrue(sut.accounts.isEmpty)
        await sut.fetchAccounts()
        // yield a few times to allow publisher to be updated with new account values
        await Task.megaYield()
        XCTAssertEqual(sut.accounts.elements, Factory.accounts)
    }

    func testFetchCategoryValues() async throws {
        // Given
        let budgetProvider = Factory.createBudgetProvider()
        sut = BudgetClient(provider: budgetProvider, selectedBudgetId: "Budget1")

        XCTAssertTrue(sut.categoryGroups.isEmpty)
        XCTAssertTrue(sut.categories.isEmpty)

        await sut.fetchBudgetSummaries()
        await Task.megaYield()
        
        // when
        await sut.fetchCategoryValues()
        await Task.megaYield()
        XCTAssertEqual(sut.categoryGroups.elements, Factory.categoryGroup)
        XCTAssertEqual(sut.categories.elements, Factory.categories)
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

    func testFetchTransactions() async throws {
        // given
        sut = try await Factory.createBudgetClientWithSelectBudgetId("Budget1")
        let startDate = Date.iso8601Formatter.date(from: "2024-02-01")!
        let finishDate = Date.iso8601Formatter.date(from: "2024-03-30")!

        // when
        let transactions = try await sut.fetchTransactions(startDate: startDate, finishDate: finishDate)

        // then
        XCTAssertEqual(transactions.count, 2)
    }
}

private enum Factory {

    static func createBudgetClientWithSelectBudgetId(_ budgetId: String) async throws -> BudgetClient {
        let provider = createBudgetProvider()
        let client = BudgetClient(provider: provider)

        await client.fetchBudgetSummaries()
        await Task.megaYield()
        XCTAssertNil(client.selectedBudgetId)
        try client.updateSelectedBudgetId(budgetId)

        return client
    }

    static func createBudgetProvider(
        budgetSummaries: [BudgetSummary]? = nil,
        accounts: [Account]? = nil,
        categoryValues: ([CategoryGroup],[BudgetSystemService.Category])? = nil,
        transactions: [TransactionEntry]? = nil
    ) -> BudgetProvider {
        .init {
            budgetSummaries ?? Self.budgetSummaries
        } fetchAccounts: { budgetId in
            accounts ?? Self.accounts
        } fetchCategoryValues: { params in
            categoryValues ?? (categoryGroup, categories)
        } fetchTransactions: { params in
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
            .init(id: "01", name: "First", deleted: false),
            .init(id: "02", name: "Second", deleted: false),
            .init(id: "03", name: "Third", deleted: false),
        ]
    }

    static var categoryGroup: [CategoryGroup] {
        [
            .init(id: "CG1", name: "Fixed Expenses", hidden: false, deleted: false, categoryIds: ["CAT1"]),
            .init(id: "CG2", name: "Transportation", hidden: false, deleted: false, categoryIds: ["CAT2","CAT3"])
        ]
    }

    static var categories: [BudgetSystemService.Category] {
        [
            .init(
                id: "CAT1",
                categoryGroupId: "GC1",
                name: "Rent",
                hidden: false,
                note: nil,
                balance: Money(123.45, currency: .AUD),
                deleted: false
            ),
            .init(
                id: "CAT2",
                categoryGroupId: "GC2",
                name: "Train Ticket",
                hidden: false,
                note: nil,
                balance: Money(40.50, currency: .AUD),
                deleted: false
            ),
            .init(
                id: "CAT3",
                categoryGroupId: "GC2",
                name: "Taxi / Uber",
                hidden: false,
                note: nil,
                balance: Money(20.00, currency: .AUD),
                deleted: false
            )
        ]
    }

    static var transactions: [TransactionEntry] {
        [
            .init(
                id: "T1",
                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
                money: Money(Decimal(-100), currency: .AUD), 
                payeeName: "Coles",
                accountId: "A1",
                accountName: "Account First",
                categoryId: "C1",
                categoryName: "Groceries",
                categoryGroupId: "CG01",
                categoryGroupName: "Acme",
                transferAccountId: nil,
                deleted: false
            ),
            .init(
                id: "T2",
                date: Date.iso8601Formatter.date(from: "2024-03-04")!,
                money: Money(Decimal(-123.45), currency: .AUD), 
                payeeName: "Engerix",
                accountId: "A1",
                accountName: "Account First",
                categoryId: "C2",
                categoryName: "Electricity Bill",
                categoryGroupId: "CG02",
                categoryGroupName: "Bills",
                transferAccountId: nil,
                deleted: false
            ),
            .init(
                id: "T3",
                date: Date.iso8601Formatter.date(from: "2024-04-05")!,
                money: Money(Decimal(-299.99), currency: .AUD), 
                payeeName: "Landlord",
                accountId: "A2",
                accountName: "Account Second",
                categoryId: "C3",
                categoryName: "Rent",
                categoryGroupId: "CG03",
                categoryGroupName: "Home Expenses",
                transferAccountId: nil,
                deleted: false
            )
        ]
    }
}
