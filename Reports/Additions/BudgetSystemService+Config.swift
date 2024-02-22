// Created by Daniel Amoafo on 19/2/2024.

import BudgetSystemService
import Dependencies

private var _liveValue: BudgetClient = .noActiveClient
private let _accessTokenKey = "ynab-access-token"

extension BudgetClient {

    static func makeClient(accessToken: String? = nil, store: KeyValueStore = SecureKeyValueStore()) -> BudgetClient {
        guard let accessToken = accessToken ?? store.string(forKey: _accessTokenKey) else {
            return .noActiveClient
        }
        let selectedBudgetId = store.string(forKey: "ynab-selected-budget-id")
        storeAccessToken(accessToken: _accessTokenKey, store: store)

        return .init(provider: .ynab(accessToken: accessToken), selectedBudgetId: selectedBudgetId)
    }

    static func storeAccessToken(accessToken: String, store: KeyValueStore = SecureKeyValueStore()) {
        store.set(_accessTokenKey, forKey: _accessTokenKey)
    }
}

extension BudgetClient: DependencyKey {

    public static var liveValue: BudgetClient {
        if case .loggedIn = _liveValue.authorizationStatus {
            // use the cached client if it's logged in
            return _liveValue
        }

        _liveValue = makeClient()

        return _liveValue
    }
}

extension BudgetClient: TestDependencyKey {
    public static var testValue: BudgetClient {
        let budgetProvider = BudgetProvider(fetchAccounts: { _ in return [] })
        return BudgetClient(provider: budgetProvider, selectedBudgetId: "someTestId")
    }
}

extension DependencyValues {
    var budgetClient: BudgetClient {
        get { self[BudgetClient.self] }
        set { self[BudgetClient.self] = newValue }
    }
}
