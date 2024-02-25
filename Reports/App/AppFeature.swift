// Created by Daniel Amoafo on 18/2/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {

    @ObservableState
    struct State: Equatable {
        var appIntroLogin = AppIntroLogin.State()
    }

    enum Action {
        case onOpenURL(URL)
        case appIntroLogin(AppIntroLogin.Action)
        case onAppear
    }

    @Dependency(\.budgetClient) var budgetClient

    var logger = LogFactory.create(category: .appFeature)

    var body: some ReducerOf<Self> {
        Scope(state: \.appIntroLogin, action: \.appIntroLogin) {
            AppIntroLogin()
        }
        Reduce { state, action in
            switch action {
            case let .onOpenURL(url):
                handleOpenURL(url, state: &state)
                return .none
            case .appIntroLogin:
                return .none
            case .onAppear:
                performOnAppear()
                return .none
            }
        }
    }
}

private extension AppFeature {

    func handleOpenURL(_ url: URL, state: inout State) {
        guard url.isDeeplink, let host = url.host() else {
            logger.warning("supplied url was not a known deeplink path. \(url)")
            return
        }

        switch host {
        case "oauth":
            if let accessToken = url.fragmentItems?["access_token"], accessToken.isNotEmpty {
                BudgetClient.storeAccessToken(accessToken: accessToken)
                budgetClient.updateProvider(.ynab(accessToken: accessToken))
                state.appIntroLogin.showSafariBrowser = nil
            }
        default:
            break
        }
    }

    func performOnAppear() {
        // check if auth token is valid
    }
}
