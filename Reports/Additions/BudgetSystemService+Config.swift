// Created by Daniel Amoafo on 19/2/2024.

import BudgetSystemService
import Dependencies

private var _liveValue: BudgetClient = .noActiveClient
private let _accessTokenKey = "ynab-access-token"

extension BudgetClient {

    func updateYnabProvider(with accessToken: String) {
        Self.storeAccessToken(accessToken: accessToken)
        updateProvider(.ynab(accessToken: accessToken))
    }

    static func makeClient(
        accessToken: String? = nil,
        bugdetProvider: BudgetProvider? = nil,
        store: KeyValueStore = SecureKeyValueStore()
    ) -> BudgetClient {
        guard let accessToken = accessToken ?? store.string(forKey: _accessTokenKey) else {
            return .noActiveClient
        }

        storeAccessToken(accessToken: accessToken, store: store)

        // use the provided budgetProvider otherwise default to ynab budget provider
        let provider: BudgetProvider = bugdetProvider ?? .ynab(accessToken: accessToken)

        @Dependency(\.configProvider) var configProvider
        let selectedBudgetId = configProvider.storedSelectedBudgetId
        return .init(provider: provider, selectedBudgetId: selectedBudgetId)
    }

    static func storeAccessToken(accessToken: String, store: KeyValueStore = SecureKeyValueStore()) {
        store.set(accessToken, forKey: _accessTokenKey)
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
        let budgetProvider = BudgetProvider(
            fetchBudgetSummaries: { return [] }, fetchAccounts: { _ in return [] }
        )
        return BudgetClient(provider: budgetProvider)
    }
}

extension DependencyValues {
    var budgetClient: BudgetClient {
        get { self[BudgetClient.self] }
        set { self[BudgetClient.self] = newValue }
    }
}
