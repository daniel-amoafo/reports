//  Created by Daniel Amoafo on 3/2/2024.

import BudgetSystemService
import Combine
import ComposableArchitecture
import SwiftData
import SwiftUI

@Reducer
struct AppFeature {

    @ObservableState
    struct State {
        var appIntroLogin = AppIntroLogin.State()
        var mainTab = MainTab.State()
        var authStatus: AuthorizationStatus = .unknown
        var showRetryLoading: Bool = false
        let connectionCheckTimeout: Double = 10.0
    }

    enum Action {
        case onOpenURL(URL)
        case appIntroLogin(AppIntroLogin.Action)
        case mainTab(MainTab.Action)
        case didUpdateAuthStatus(AuthorizationStatus)
        case checkRetryConnection
        case onAppear
        case onTask
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.database.grdb) var grdb
    @Dependency(\.configProvider) var configProvider
    @Dependency(\.continuousClock) var clock

    private let logger = LogFactory.create(Self.self)

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
                let oldStatus = state.authStatus
                logger.debug("authStatus update new: \(newStatus), old: \(oldStatus)")
                state.authStatus = newStatus
                return .run { _ in
                    if newStatus == .loggedIn, oldStatus == .loggedOut {
                        // make sure we have fresh data if previously loggedOut state
                        await syncBudgetData()
                    }
                }

            case .checkRetryConnection:
                if state.authStatus == .unknown {
                    state.showRetryLoading = true
                }
                return .none

            case .onAppear:
                state.showRetryLoading = false
                return .run { [connectionCheckTimeout = state.connectionCheckTimeout] send in
                    await performOnAppear()
                    // retry connection if authorization status not updated
                    try await self.clock.sleep(for: .seconds(connectionCheckTimeout))
                    await send(.checkRetryConnection, animation: .default)
                }

            case .onTask:
                return .run { send in
                    await startAsyncListeners(send: send)
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
                Task {
                    await syncBudgetData()
                }
            }
        default:
            break
        }
    }

    func performOnAppear() async {
          await syncBudgetData()
    }

    /// Spawns unstructured Async Task to monitor for budgetClient changes.
    func startAsyncListeners(send: Send<AppFeature.Action>) async {

        Task {
            // Monitor when the budgetId changes and sync db values for the new selectedBudgetId
            for await _ in budgetClient.$selectedBudgetId.stream {
//                await syncBudgetData()
            }
        }

        // await the last task to keep the run effect from completing.
        // A Reducer run effect cannot complete if send actions will be emitted.
        await Task {
            // Monitor authorization satus updates
            for await status in budgetClient.$authorizationStatus.stream {
                await send(.didUpdateAuthStatus(status))
            }
        }.value
    }

    func syncBudgetData() async {
        do {
            WorkspaceValues.clearAll()
            guard try await syncBudgetSummaries() else {
                return
            }
            try syncWorkspaceValues()
            try await syncCategoryValues()
            try await syncTransactionHistory()

        } catch {
            logger.error("\(String(describing: error))")
            // !! User friendly alert required to flag something important hasn't completed.
        }
    }

    /// Load account names into memory, it's access by multiple screens
    /// This reduces database I/O fetches
    func syncWorkspaceValues() throws {

        guard let budgetId = configProvider.selectedBudgetId else { return }
        let accounts = try Account.fetchAll(budgetId: budgetId)

        let accountNames = accounts.reduce(into: [String: String]()) {
            $0[$1.id] = $1.name
        }
        @Shared(.wsValues) var workspaceValues
        workspaceValues.accountsOnBudgetNames = accountNames
        logger.debug("Synced workspace values")
    }

    func syncBudgetSummaries() async throws -> Bool {
        let summaries = try await budgetClient.fetchBudgetSummaries()
        guard summaries.isNotEmpty else {
            logger.warning("No budget summaries fetched! Halting db sync.")
            return false
        }
        logger.debug("Syncing summaries and accounts to db...")
        try BudgetSummary.save(summaries)

        return true
    }

    func syncCategoryValues() async throws {
        guard let selectedId = configProvider.selectedBudgetId else { return }

        let lastServerKnowledge = try ServerKnowledgeConfig.fetch(budgetId: selectedId)?.categories
        let (groups, categories, newServerKnowledge) = await budgetClient.fetchCategoryValues(
            budgetId: selectedId,
            lastServerKnowledge: lastServerKnowledge
        )

        if groups.isEmpty && categories.isEmpty {
            logger.debug("No new / updated category values since last sync.")
            return
        }

        logger.debug("Syncing category values to db...")
        try CategoryRecord.save(
            groups: groups,
            categories: categories,
            serverKnowledge: newServerKnowledge
        )
    }

    func syncTransactionHistory() async throws {
        guard let selectedId = configProvider.selectedBudgetId else { return }

        let lastServerKnowledge = try ServerKnowledgeConfig.fetch(budgetId: selectedId)?.transactions
        let (transactions, newServerKnowledge) = try await budgetClient
            .fetchAllTransactions(budgetId: selectedId, lastServerKnowledge: lastServerKnowledge)

        guard transactions.isNotEmpty else {
            logger.debug("No new / updated transactions since last sync.")
            return
        }

        logger.debug("Syncing transaction history to db...")
        try TransactionEntry.save(transactions, serverKnowledge: newServerKnowledge)
    }

}

@main
struct ReportsApp: App {
    @State var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var modelContext: ModelContext {
        @Dependency(\.database) var database
        return database.swiftData
    }

    var body: some Scene {
        WindowGroup {
            // during tests, dont run main app code as this may conflict with tests runs
            if !_XCTIsTesting {
                rootView
                    .onOpenURL(perform: { url in
                        store.send(.onOpenURL(url))
                    })
                    .onAppear {
                        store.send(.onAppear)
                    }
                    .task {
                        store.send(.onTask)
                    }
            }
        }
        .modelContext(modelContext)
    }

    private var rootView: some View {
        ZStack {
            Color.Surface.primary
                .ignoresSafeArea()
            switch store.authStatus {
            case .unknown:
                VStack {
                    // check if reattempt of loading is required by user if connection timeout reached.
                    if store.showRetryLoading {
                        Text(Strings.reconnectText)
                            .typography(.title3Emphasized)
                            .multilineTextAlignment(.center)
                        HStack {
                            Spacer().frame(minWidth: 20.0)
                            Button(Strings.reconnectButtonTitle) {
                                store.send(.onAppear, animation: .default)
                            }
                            .buttonStyle(.kleonOutline)
                            Spacer().frame(minWidth: 20.0)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding()
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
    }
}

// MARK: - Strings

private enum Strings {
    static let reconnectText = String(
        localized: "Hmm, something went wrong.\nPlease try again",
        comment: "text displayed when unable to load screen into a valid state. Ask the user to retry"
    )
    static let reconnectButtonTitle = String(
        localized: "Reconnect",
        comment: "Button title when unable to load app to a valid state"
    )
}
