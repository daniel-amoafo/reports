// Created by Daniel Amoafo on 3/6/2024.

import ComposableArchitecture
import Foundation

/// Shared State Object that allows data values used in multiple screens to access
/// or updated.
/// To be used with the `@Shared` TCA  fixture.
struct WorkspaceValues: Equatable {

    var accountsOnBudgetNames = [String: String]()
    var selectedAccountIdsSet = Set<String>()
}

extension WorkspaceValues {

    static func clearAll() {
        @Shared(.wsValues) var workspaceValues = .init()
    }

    var selectedAccountIds: String? {
        guard selectedAccountIdsSet.isNotEmpty else { return nil }
        return selectedAccountIdsSet.joined(separator: ",")
    }

    var selectedAccountOnBudgetIdNames: String? {
        accountNames(for: selectedAccountIdsSet)
    }

    func accountNames(for ids: String?) -> String? {
        guard let ids else { return nil }
        let set = makeSet(for: ids)
        return accountNames(for: set)
    }

    func accountNames(for ids: Set<String>) -> String? {
        let accounts = accountsOnBudgetNames
        guard ids.isNotEmpty else { return nil }
        if ids.count == accounts.count {
            return AppStrings.allAccountsName
        }
        guard ids.count < 3 else {
            return AppStrings.someAccountsName
        }
        let names = accounts
            .filter { ids.contains($0.key) }
            .map(\.value)
            .joined(separator: ", ")
        return names
    }

    mutating func updateSelecteAccountIds(ids: String?) {
        guard let ids else {
            selectedAccountIdsSet = .init()
            return
        }
        selectedAccountIdsSet = makeSet(for: ids)
    }

    func makeSet(for ids: String) -> Set<String> {
        let array = ids
            .split(separator: ",")
            .map(String.init)
        return .init(array)
    }
}

extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<WorkspaceValues>> {
  static var wsValues: Self {
      PersistenceKeyDefault(.inMemory("workspaceValues"), .init())
  }
}
