//  Created by Daniel Amoafo on 3/2/2024.

import BudgetSystemService
import Combine
import ComposableArchitecture
import SwiftUI

private var subscribers: Set<AnyCancellable> = []

@Reducer
struct AppFeature {

    @ObservableState
    struct State: Equatable {
        var appIntroLogin = AppIntroLogin.State()
        var mainTab = MainTab.State()
        var authStatus: AuthorizationStatus = .unknown
    }

    enum Action {
        case onOpenURL(URL)
        case appIntroLogin(AppIntroLogin.Action)
        case mainTab(MainTab.Action)
        case didUpdateAuthStatus(AuthorizationStatus)
        case onAppear
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.configProvider) var configProvider

    var logger = LogFactory.create(category: .appFeature)

    var body: some ReducerOf<Self> {
        Scope(state: \.appIntroLogin, action: \.appIntroLogin) {
            AppIntroLogin()
        }
        Scope(state: \.mainTab, action: \.mainTab) {
            MainTab()
        }
        Reduce { state, action in
            switch action {
            case let .onOpenURL(url):
                handleOpenURL(url, state: &state)
                return .none

            case .appIntroLogin:
                return .none
            case .mainTab:
                return .none
            case let .didUpdateAuthStatus(newStatus):
                guard newStatus != state.authStatus else { return  .none }
                state.authStatus = newStatus
                logger.debug("authStatus update: \(newStatus)")
                return .none
//                return .run { _ in
//                    await loadBudgetClientData()
//                }
            case .onAppear:
                return .run { send in
                    await performOnAppear(send: send)
                }
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
                budgetClient.updateYnabProvider(accessToken)
                state.appIntroLogin.showSafariBrowser = nil
                logger.info("oauth url path handled, updated budget client with new access token.")
            }
        default:
            break
        }
    }

    func performOnAppear(send: Send<AppFeature.Action>) async {
        await loadBudgetClientData()

        // Monitor authorization satus updates
        for await status in budgetClient.$authorizationStatus.values {
            await send(.didUpdateAuthStatus(status))
            logger.debug("did update auth status to: \(status)")
        }

        for await selectedBudgetId in budgetClient.$selectedBudgetId.values {
            logger.debug("storing selectedBudget \(selectedBudgetId ?? "")")
        }

    }

    func loadBudgetClientData() async {
        logger.debug("\(#function) - fetching budgetClient data")
        await budgetClient.fetchBudgetSummaries()
        await budgetClient.fetchAccounts()
    }

}

@main
struct ReportsApp: App {
    @State var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch store.authStatus {
                case .unknown:
                    ProgressView()
                case .loggedIn:
                    MainTabView(
                        store: store.scope(state: \.mainTab, action: \.mainTab)
                    )
                case .loggedOut:
                    AppIntroLoginView(
                        store: store.scope(state: \.appIntroLogin, action: \.appIntroLogin)
                    )
                }
            }
            .onOpenURL(perform: { url in
                store.send(.onOpenURL(url))
            })
            .task {
                store.send(.onAppear)
            }
        }
    }
}
