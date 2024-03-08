// Created by Daniel Amoafo on 7/3/2024.

import Dependencies
import Foundation

struct ConfigProvider {

    enum Key: String {
        case oathPath = "cw-oath-path"
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
}

extension ConfigProvider: DependencyKey {
    static var liveValue: ConfigProvider {
        .init()
    }
}

extension DependencyValues {
    var configProvider: ConfigProvider {
        get { self[ConfigProvider.self] }
        set { self[ConfigProvider.self] = newValue }
    }
}
