// Created by Daniel Amoafo on 3/6/2024.

import ComposableArchitecture
import Foundation
import MoneyCommon

/// Shared State Object that allows data values used in multiple screens to access
/// or updated.
/// To be used with the `@Shared` TCA  property wrapper.
struct WorkspaceValues: Equatable {

    private let displayAccountNamesThreshold = 2

    /// Dictionary of `Account` Id as the key and the account name as the value
    var accountsOnBudgetNames = [String: String]()

    /// The currency associated to the selected budget.
    /// The default value will be overwritten when a budget is selected
    /// during onboarding see the `AppFeature` syncWorkspaceValues.
    var budgetCurrency: Currency = Currency.XCD

    /// scratch area for screen to set the selected account ids.
    /// Used by the `ReportInputFeature` and `SelectAccountsFeature`
    /// to communicate which  account ids are selected
    var selectedAccountIdsSet = Set<String>()
}

extension WorkspaceValues {

    static func clearAll() {
        @Shared(.workspaceValues) var workspaceValues
        workspaceValues = .init()
    }

    var selectedAccountIds: String? {
        guard selectedAccountIdsSet.isNotEmpty else { return nil }
        return selectedAccountIdsSet.joined(separator: ",")
    }

    var selectedAccountOnBudgetIdNames: String? {
        accountOnBudgetNames(for: selectedAccountIdsSet)
    }

    /// Retrieve's the account names for each respective id provided in the given comma separated list of id's
    /// See `accountOnBudgetNames(for ids: Set<String>)` for logic rules on what name is provided given
    /// the count of id's to return
    func accountOnBudgetNames(for ids: String?) -> String? {
        guard let ids else { return nil }
        let set = Self.makeSet(for: ids)
        return accountOnBudgetNames(for: set)
    }

    /// Returns a list of budget names for a given set of id's.
    /// If id's match the available account Names, return "All Accounts" string
    /// If id's equal to or less than the `displayAccountNamesThreshold` return "some Accounts" string.
    func accountOnBudgetNames(for ids: Set<String>) -> String? {
        let accounts = accountsOnBudgetNames
        guard ids.isNotEmpty else { return nil }
        if ids == Set(accounts.keys) {
            return AppStrings.allAccountsTitle
        }

        guard ids.count <= displayAccountNamesThreshold  else {
            return AppStrings.someAccountsTitle
        }
        let names = accounts
            .filter { ids.contains($0.key) }
            .map(\.value)
            .sorted()
            .joined(separator: ", ")
        return names
    }

    mutating func updateSelectedAccountIds(ids: String?) {
        guard let ids else {
            selectedAccountIdsSet = .init()
            return
        }
        selectedAccountIdsSet = Self.makeSet(for: ids)
    }

    static func makeSet(for ids: String?) -> Set<String> {
        guard let ids, ids.isNotEmpty else { return .init() }
        let array = ids
            .split(separator: ",")
            .map(String.init)
        return .init(array)
    }
}

extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<WorkspaceValues>> {
  static var workspaceValues: Self {
      PersistenceKeyDefault(.inMemory("workspaceValues"), .init())
  }
}
