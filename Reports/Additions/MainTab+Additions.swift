// Created by Daniel Amoafo on 8/5/2024.

import SwiftUI

// This should reside in the MainTabView.swift however due to a circlur referece macro error
// extensions need to housed in a separate file when a struct/class has a macro annotation
// see: https://forums.swift.org/t/macro-circular-reference-error-when-adding-extensions-to-a-type-decorated-by-a-peer-macro/68064
extension MainTab.Tab {

    var title: String {
        switch self {
        case .home: return Strings.homeTitle
        case .reports: return Strings.reportsTitle
        case .settings: return Strings.settingsTitle
        }
    }

    var imageName: String {
        switch self {
        case .home: return "house.fill"
        case .reports: return "chart.xyaxis.line"
        case .settings: return "slider.horizontal.3"
        }
    }
}

private enum Strings {
    static let homeTitle = String(localized: "Home", comment: "Home screen tab title name")
    static let reportsTitle = String(localized: "Reports", comment: "Saved Reports screen tab title name")
    static let settingsTitle = String(localized: "Settings", comment: "Settings screen tab title name")
}
