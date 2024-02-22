//
//  ReportsApp.swift
//  Reports
//
//  Created by Daniel Amoafo on 3/2/2024.
//

import BudgetSystemService
import Dependencies
import SwiftUI

@main
struct ReportsApp: App {
    var body: some Scene {
        WindowGroup {
            AppIntroLogin()
                .onOpenURL(perform: { url in
                    handleOpenURL(url)
                })
        }
    }
}

extension ReportsApp {

    private func handleOpenURL(_ url: URL) {
        guard url.isDeeplink, let host = url.host() else {
            debugPrint("supplied url was not a known deeplink path. \(url)")
            return
        }

        if host == "oauth",
           let accessToken = url.fragmentItems?["access_token"],
           accessToken.isNotEmpty {

            @Dependency(\.budgetClient) var budgetClient
            BudgetClient.storeAccessToken(accessToken: accessToken)
            budgetClient.updateProvider(.ynab(accessToken: accessToken))
        }
    }
}

enum TabIdentifier: Hashable {
  case home, settings
}

// var tabIdentifier: TabIdentifier? {
//    guard isDeeplink else { return nil }
//
//    switch host {
//    case "home": return .home // matches my-url-scheme://home/
//    case "settings": return .settings // matches my-url-scheme://settings/
//    default: return nil
//    }
// }
