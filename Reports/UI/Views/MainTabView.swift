// Created by Daniel Amoafo on 8/3/2024.

import ComposableArchitecture
import SwiftUI

@Reducer
struct MainTab {

    enum Tab: Sendable { case home, reports, settings }

    @ObservableState
    struct State {
        var currentTab = Tab.home
        var home = HomeFeature.State()
        var savedReports = SavedReportsFeature.State()
        @Presents var report: ReportFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Sendable {
        case home(HomeFeature.Action)
        case savedReports(SavedReportsFeature.Action)
        case report(PresentationAction<ReportFeature.Action>)
        case showSavedReport
        case selectTab(Tab)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum Alert: Equatable { }
    }

    let logger = LogFactory.create(Self.self)
    @Dependency(\.savedReportQuery) var savedReportQuery

    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.savedReports, action: \.savedReports) {
            SavedReportsFeature()
        }
        Reduce { state, action in
            switch action {
            case let .home(.delegate(.navigate(to: tab))):
                state.currentTab = tab
                return .none

            case let .home(.delegate(.presentReport(source))):
                do {
                    state.report = try ReportFeature.State(sourceData: source)
                } catch {
                    logger.error("\(error.toString())")
                    state.alert = .unableToOpenSavedReport
                }
                return .none

            case let .savedReports(.delegate(.rowTapped(id))):
                do {
                    state.report = try .init(sourceData: .existing(id))
                } catch {
                    logger.error("\(error.toString())")
                    state.alert = .unableToOpenSavedReport
                }
                return .none

            case let .selectTab(tab):
                state.currentTab = tab
                return .none

            case .home, .savedReports, .showSavedReport, .report, .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$report, action: \.report) {
            ReportFeature()
        }
    }
}

// MARK: -

struct MainTabView: View {
    @Bindable var store: StoreOf<MainTab>

    var body: some View {
        TabView(selection: $store.currentTab.sending(\.selectTab)) {
            Group {
                // Home Tab
                NavigationStack {
                    HomeView(
                        store: self.store.scope(state: \.home, action: \.home)
                    )
                }
                .tag(MainTab.Tab.home)
                .tabItem { tabItemView(for: .home) }

                // Saved Reports Tab
                NavigationStack {
                    SavedReportsView(
                        store: store.scope(state: \.savedReports, action: \.savedReports)
                    )
                }
                .tag(MainTab.Tab.reports)
                .tabItem { tabItemView(for: .reports) }

                // Saved Reports Tab
                NavigationStack {
                    SettingsView()
                }
                .tag(MainTab.Tab.settings)
                .tabItem { tabItemView(for: .settings) }
            }
            .toolbarBackground(.visible, for: .tabBar)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .fullScreenCover(item: $store.scope(state: \.report, action: \.report)) { store in
            NavigationStack {
                ReportView(store: store)
            }
        }
    }
}

private extension MainTabView {

    func tabItemView(for tab: MainTab.Tab) -> some View {
        VStack {
            Text(tab.title)
            Image(systemName: tab.imageName)
        }
    }
}

private extension AlertState {

    static var unableToOpenSavedReport: Self {
        AlertState {
            TextState(Strings.savedReportAlert)
        } actions: {
            ButtonState(role: .cancel) {
                TextState(AppStrings.okButtonTitle)
            }
        } message: {
            TextState(Strings.savedReportMessage)
        }
    }
}

private enum Strings {
    static let savedReportAlert = String(localized: "Saved Report", comment: "The saved report alert title")

    static let savedReportMessage = String(
        localized: "Hmmm, the saved report appears invalid. It cannot be opened.",
        comment: "Message displayed when unable to open a saved report because data is no longer valid"
    )
}

// MARK: - Preview

#Preview {
    MainTabView(
        store: Store(initialState: MainTab.State()) {
            MainTab()
        }
    )
}
