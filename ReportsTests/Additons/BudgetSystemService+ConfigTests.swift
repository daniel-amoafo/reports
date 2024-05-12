// Created by Daniel Amoafo on 25/2/2024.

import BudgetSystemService
import ConcurrencyExtras
import Foundation
@testable import Reports
import XCTest

final class BudgetSystemServiceConfigTests: XCTestCase {

    let accessTokenKey =  "ynab-access-token"

    func testStoreAccessToken() {
        let store = InMemoryKeyValueStore()
        let token = "this is the token value"
        BudgetClient.storeAccessToken(accessToken: token, store: store)

        XCTAssertEqual(store.string(forKey: accessTokenKey), token)
    }

    func testMakeClientSuccess() async throws {
        // given
        let env = Factory.createBudgetClient(accessToken: "someAccessToken")
        XCTAssertEqual(env.store.string(forKey: accessTokenKey), "someAccessToken")

        try await withMainSerialExecutor {
            // when
            XCTAssertTrue(env.client.budgetSummaries.isEmpty)
            await env.client.fetchBudgetSummaries()
            await Task.megaYield()
            // then
            XCTAssertTrue(env.client.budgetSummaries.isNotEmpty)

            // when
            XCTAssertTrue(env.client.accounts.isEmpty)
            try env.client.updateSelectedBudgetId("2")
            await env.client.fetchAccounts()
            await Task.megaYield()
            // then
            XCTAssertTrue(env.client.accounts.isNotEmpty)
        }
    }

    func testMakeClientWithNoToken() async throws {
        // given
        let env = Factory.createBudgetClient()

        await withMainSerialExecutor {
            // when
            XCTAssertTrue(env.client.budgetSummaries.isEmpty)
            await env.client.fetchBudgetSummaries()
            await Task.megaYield()
            // then
            XCTAssertTrue(env.client === BudgetClient.notAuthorizedClient)
            XCTAssertTrue(env.client.budgetSummaries.isEmpty)
        }
    }
}

private enum Factory {

    /// Helper struct allowing client & injected dependencies to be accessed
    struct Env {
        let client: BudgetClient
        let budgetProvider: BudgetProvider
        let store: KeyValueStore
    }

    /// Helper method to construct a `BudgetClient` and provide references to dependencies
    /// via the `Env` struct  used in construction
    static func createBudgetClient(accessToken: String? = nil) -> Env {
        let budgetProvider = mockBudgetProvider
        let store: KeyValueStore = InMemoryKeyValueStore()
        let client = BudgetClient.makeClient(
            accessToken: accessToken,
            bugdetProvider: budgetProvider,
            store: store
        )

        return .init(client: client, budgetProvider: budgetProvider, store: store)
    }

    static var mockBudgetProvider: BudgetProvider {
        return .init {
            .mocks
        } fetchAccounts: { _ in
                .mocks
        } fetchCategoryValues: { _ in
            ([], [])
        } fetchTransactions: { _ in
            []
        }
    }

}

extension Array where Element == Account {

    static let mocks: Self = [
        .init(id: "01", name: "First Account", onBudget: true, deleted: false),
        .init(id: "02", name: "Second Account", onBudget: true, deleted: false),
        .init(id: "03", name: "Third Account", onBudget: true, deleted: false),
    ]
}

extension Array where Element == BudgetSummary {

    static let mocks: Self = [
        .init(
            id: "1",
            name: "Summary One",
            lastModifiedOn: "Yesterday",
            firstMonth: "March",
            lastMonth: "May",
            currency: .AUD
        ),
        .init(
            id: "2",
            name: "Summary Two",
            lastModifiedOn: "Days ago",
            firstMonth: "April",
            lastMonth: "Jun",
            currency: .AUD
        ),
    ]

}
