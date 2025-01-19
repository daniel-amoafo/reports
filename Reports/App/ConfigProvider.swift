// Created by Daniel Amoafo on 7/3/2024.

import BudgetSystemService
import Dependencies
import Foundation
import MoneyCommon

struct ConfigProvider {

    private let defaultStore: KeyValueStore
    private let secureStore: KeyValueStore

    let charts: [ReportChart]

    enum Key: String {
        case oauthPath = "cw-oauth-path"
        case selectedBudgetId = "selected-Budget-Id"
    }

    init(
        defaultStore: KeyValueStore = UserDefaults.standard,
        secureStore: KeyValueStore = SecureKeyValueStore()
    ) {
        self.defaultStore = defaultStore
        self.secureStore = secureStore
        self.charts = ReportChart.defaultCharts.elements
    }

    private var infoDict: [String: Any]? {
        Bundle.main.infoDictionary
    }

    var oauthPath: String {
        guard let path = infoDict?[Key.oauthPath.rawValue] as? String else {
            fatalError("\(Key.oauthPath.rawValue) was unexpectedly not defined")
        }
        return path
    }

    var currency: Currency? {
        guard let selectedBudgetId else { return nil }
        return try? BudgetSummary.fetch(id: selectedBudgetId)?.currency
    }

    var selectedBudgetId: String? {
        defaultStore.string(forKey: Key.selectedBudgetId.rawValue)
    }

    func setSelectedBudgetId(_ id: String) {
        guard id != selectedBudgetId else {
            return
        }
        defaultStore.set(id, forKey: Key.selectedBudgetId.rawValue)
    }
}

extension ConfigProvider: Equatable {
    static func == (lhs: ConfigProvider, rhs: ConfigProvider) -> Bool {
        return lhs.oauthPath == rhs.oauthPath &&
        lhs.selectedBudgetId == rhs.selectedBudgetId
    }
}

extension ConfigProvider: DependencyKey {
    static var liveValue: ConfigProvider {
        .init()
    }

    static var testValue: ConfigProvider {
        .init(defaultStore: InMemoryKeyValueStore(), secureStore: InMemoryKeyValueStore())
    }

    static var previewValue: ConfigProvider {
        let config: ConfigProvider = .init(
            defaultStore: InMemoryKeyValueStore(), secureStore: InMemoryKeyValueStore()
        )
        MockData.insertConfigData(config)
        return config
    }
}

extension DependencyValues {
    var configProvider: ConfigProvider {
        get { self[ConfigProvider.self] }
        set { self[ConfigProvider.self] = newValue }
    }
}
