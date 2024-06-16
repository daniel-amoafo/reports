// Created by Daniel Amoafo on 19/2/2024.

import BudgetSystemService
import Dependencies

private let _accessTokenKey = "ynab-access-token"

extension BudgetClient {

    func updateYnabProvider(_ accessToken: String, store: KeyValueStore = SecureKeyValueStore()) {
        Self.storeAccessToken(accessToken: accessToken, store: store)
        updateProvider(.ynab(accessToken: accessToken))
    }

    func logout(store: KeyValueStore = SecureKeyValueStore()) {
        Self.storeAccessToken(accessToken: nil, store: store)
        updateProvider(.notAuthorized)
        authorizationStatus = .loggedOut
    }

    static func makeLiveClient(
        accessToken: String? = nil,
        bugdetProvider: BudgetProvider? = nil,
        store: KeyValueStore = SecureKeyValueStore()
    ) -> BudgetClient {
        guard let accessToken = accessToken ?? store.string(forKey: _accessTokenKey) else {
            return .notAuthorizedClient
        }

        storeAccessToken(accessToken: accessToken, store: store)

        // use the supplied budgetProvider otherwise default to ynab budget provider
        let provider: BudgetProvider = bugdetProvider ?? .ynab(accessToken: accessToken)

        return .init(provider: provider)
    }

    static func storeAccessToken(accessToken: String?, store: KeyValueStore = SecureKeyValueStore()) {
        guard let accessToken else {
            store.removeValue(forKey: _accessTokenKey)
            return
        }
        store.set(accessToken, forKey: _accessTokenKey)
    }
}

extension BudgetClient: @retroactive DependencyKey {

    nonisolated(unsafe) public static let liveValue = BudgetClient.makeLiveClient()

    nonisolated(unsafe) public static let testValue: BudgetClient = BudgetClient.testsAndPreviews

    nonisolated(unsafe) public static let previewValue = BudgetClient.testsAndPreviews

}

extension DependencyValues {

    var budgetClient: BudgetClient {
        get { self[BudgetClient.self] }
        set { self[BudgetClient.self] = newValue }
    }
}
