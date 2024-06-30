// Created by Daniel Amoafo on 21/6/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature: Sendable {

    @ObservableState
    struct State {
        var appIntroLogin = AppIntroLogin.State()
        var mainTab = MainTab.State()
        var onboarding = OnboardingViewFeature.State()
        var authStatus: AuthorizationStatus = .unknown
        var showRetryLoading: Bool = false
        var didCompleteOnboarding: Bool = false
        let connectionCheckTimeout: Double = 10.0

        var showOnboardingFlow: Bool {
            @Dependency(\.configProvider) var configProvider
            return configProvider.selectedBudgetId == nil
        }
    }

    enum Action: Sendable {
        case onOpenURL(URL)
        case appIntroLogin(AppIntroLogin.Action)
        case mainTab(MainTab.Action)
        case onboarding(OnboardingViewFeature.Action)
        case didUpdateAuthStatus(AuthorizationStatus)
        case checkRetryConnection
        case onAppear
        case onTask
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.database.grdb) var grdb
    @Dependency(\.configProvider) var configProvider
    @Dependency(\.continuousClock) var clock

    private static let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Scope(state: \.appIntroLogin, action: \.appIntroLogin) {
            AppIntroLogin()
        }
        Scope(state: \.mainTab, action: \.mainTab) {
            MainTab()
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingViewFeature()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case let .onOpenURL(url):
                handleOpenURL(url, state: &state)
                return .none

            case let .didUpdateAuthStatus(newStatus):
                guard newStatus != state.authStatus else { return  .none }
                let oldStatus = state.authStatus
                Self.logger.debug("authStatus update new: \(newStatus), old: \(oldStatus)")
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

            case .onboarding(.delegate(.didComplete)):
                state.didCompleteOnboarding = true
                return .run { _ in
                    await performOnAppear()
                }

            case .onTask:
                return .run { send in
                    await startAsyncListeners(send: send)
                }

            case .appIntroLogin, .mainTab, .onboarding:
                return .none
            }
        }
    }
}

private extension AppFeature {

    func handleOpenURL(_ url: URL, state: inout State) {
        guard url.isDeeplink, let host = url.host() else {
            Self.logger.warning("supplied url was not a known deeplink path. \(url)")
            return
        }

        switch host {
        case "oauth":
                if let accessToken = url.fragmentItems?["access_token"], accessToken.isNotEmpty {
                    state.appIntroLogin.showSafariBrowser = nil
                    Self.logger.info("oauth url path handled, updated budget client with new access token.")
                    Task {
                        await budgetClient.updateYnabProvider(accessToken)
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

        // await the last task to keep the run effect from completing.
        // A Reducer run effect cannot complete if send actions will be emitted.
        await Task { @MainActor in
            // Monitor authorization satus updates
            for await status in await budgetClient.authorizationStatusStream {
                send(.didUpdateAuthStatus(status))
            }
        }.value
    }

    func syncBudgetData() async {
        defer {

        }
        do {
            WorkspaceValues.clearAll()
            guard try await syncBudgetSummaries() else {
                return
            }
            try syncWorkspaceValues()
            try await syncCategoryValues()
            try await syncTransactionHistory()

        } catch {
            Self.logger.error("\(String(describing: error))")
            // !! User friendly alert required to flag something important hasn't completed.
        }
    }

    /// Load account names into memory, it's access by multiple screens
    /// This reduces database I/O fetches
    func syncWorkspaceValues() throws {
        Self.logger.debug("Sync Workspace Values...")
        guard let budgetId = configProvider.selectedBudgetId else {
            Self.logger.warning("\(#function) - halted. budgetId not found")
            return
        }

        guard let budget = try BudgetSummary.fetch(id: budgetId) else {
            Self.logger.error("\(#function) - halted. a budget record could not be found for (\(budgetId)")
            return
        }

        let accounts = try Account.fetchAll(budgetId: budgetId)

        let accountNames = accounts.reduce(into: [String: String]()) {
            $0[$1.id] = $1.name
        }
        @Shared(.workspaceValues) var workspaceValues
        workspaceValues.accountsOnBudgetNames = accountNames
        workspaceValues.budgetCurrency = budget.currency
        Self.logger.debug("Workspace values synced.")
    }

    func syncBudgetSummaries() async throws -> Bool {
        let summaries = try await budgetClient.fetchBudgetSummaries()
        guard summaries.isNotEmpty else {
            Self.logger.warning("No budget summaries fetched! Halting db sync.")
            return false
        }
        Self.logger.debug("Syncing summaries and accounts to db...")
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
            Self.logger.debug("No new / updated category values since last sync.")
            return
        }

        Self.logger.debug("Syncing category values to db...")
        try CategoryGroup.save(
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
            Self.logger.debug("No new / updated transactions since last sync.")
            return
        }

        Self.logger.debug("Syncing transaction history to db...")
        try TransactionEntry.save(transactions, serverKnowledge: newServerKnowledge)
    }

}
