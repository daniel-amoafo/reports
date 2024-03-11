// Created by Daniel Amoafo on 7/3/2024.

import Dependencies
import Foundation

class ConfigProvider {

    private let defaultStore: KeyValueStore
    private let secureStore: KeyValueStore

    enum Key: String {
        case oathPath = "cw-oath-path"
        case selectedBudgetId = "selected-Budget-Id"
    }

    init(defaultStore: KeyValueStore = UserDefaults.standard, secureStore: KeyValueStore = SecureKeyValueStore()) {
        self.defaultStore = defaultStore
        self.secureStore = secureStore
    }

    private var infoDict: [String: Any]? {
        Bundle.main.infoDictionary
    }

    var oauthPath: String {
        guard let path = infoDict?[Key.oathPath.rawValue] as? String else {
            fatalError("\(Key.oathPath.rawValue) was unexpectedly not defined")
        }
        return path
    }

    var storedSelectedBudgetId: String? {
        get {
            defaultStore.string(forKey: Key.selectedBudgetId.rawValue)
        }
        set {
            guard newValue != storedSelectedBudgetId else {
                return
            }
            defaultStore.set(newValue, forKey: Key.selectedBudgetId.rawValue)
        }
    }

}

extension ConfigProvider: DependencyKey {
    static var liveValue: ConfigProvider {
        .init()
    }

    static var previewValue: ConfigProvider {
        .init(defaultStore: InMemoryKeyValueStore(), secureStore: InMemoryKeyValueStore())
    }
}

extension DependencyValues {
    var configProvider: ConfigProvider {
        get { self[ConfigProvider.self] }
        set { self[ConfigProvider.self] = newValue }
    }
}
