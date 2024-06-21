// Created by Daniel Amoafo on 21/6/2024.

import ComposableArchitecture
@testable import Reports
import Testing

@Suite
struct WorkspaceValuesTests {

    @Shared(.workspaceValues) var workspaceValues

    @Test func populateWorkspace() throws {
        // new workspace default values
        verifyDefaultValuesState()

        // update workspace with values
        $workspaceValues.withLock {
            $0.budgetCurrency = .GBP
            $0.updateSelectedAccountIds(ids: "some,set,of,account,ids")
            $0.accountsOnBudgetNames = Factory.accountNames
        }

        // verify updates
        let expectAccountIds: Set<String> = ["some", "set", "of", "account", "ids"]
        #expect(workspaceValues.selectedAccountIdsSet == expectAccountIds)
        #expect(workspaceValues.budgetCurrency == .GBP)
        #expect(workspaceValues.accountOnBudgetNames(for: "02") == "Second Account")

        // reset all values to default state
        WorkspaceValues.clearAll()
        verifyDefaultValuesState()
    }

    @Test func selectAccountNames() throws {

        $workspaceValues.withLock {
            $0.accountsOnBudgetNames = Factory.accountNames
        }

        // verify
        let actual2Accounts = workspaceValues.accountOnBudgetNames(for: "02,01")
        _ = try #require(actual2Accounts == "First Account, Second Account")

        let actualMoreThan2Accounts = workspaceValues.accountOnBudgetNames(for: "02,01,03")
        _ = try #require(actualMoreThan2Accounts == "Some Accounts")

        let allAccounts = workspaceValues.accountOnBudgetNames(for: "04,02,01,03")
        _ = try #require(allAccounts == "All Accounts")
    }

    func verifyDefaultValuesState() {
        #expect(workspaceValues.selectedAccountIds == nil)
        #expect(workspaceValues.budgetCurrency == .XCD)
        #expect(workspaceValues.accountsOnBudgetNames.isEmpty)
    }
}

private enum Factory {

    static let accountNames = [
        "01": "First Account",
        "02": "Second Account",
        "03": "Third Account",
        "04": "Fourth Account",
    ]

}
