// Created by Daniel Amoafo on 8/3/2024.

import ComposableArchitecture
import SwiftUI

@Reducer
struct MainTab {

    enum Tab { case home, reports, settings }

    @ObservableState
    struct State: Equatable {
        var currentTab = Tab.home
        var home = Home.State()
    }

    enum Action {
        case home(Home.Action)
        case selectTab(Tab)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            Home()
        }
        Reduce { state, action in
            switch action {
            case .home:
                return .none
            case let .selectTab(tab):
                state.currentTab = tab
                return .none
            }
        }
    }
}

private enum Strings {
    static let homeTitle = String(localized: "Home", comment: "Home screen tab title name")
    static let reportsTitle = String(localized: "Reports", comment: "Saved Reports screen tab title name")
    static let settingsTitle = String(localized: "Settings", comment: "Settings screen tab title name")
}

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
                    SavedReportsView()
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
    }
}

private extension MainTabView {

    func tabItemView(for tab: MainTab.Tab) -> some View {
        VStack {
            Text(tabItemTitle(for: tab))
            Image(systemName: tabItemImageName(for: tab))
        }
    }

    func tabItemTitle(for tab: MainTab.Tab) -> String {
        switch tab {
        case .home: return Strings.homeTitle
        case .reports: return Strings.reportsTitle
        case .settings: return Strings.settingsTitle
        }
    }

    func tabItemImageName(for tab: MainTab.Tab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .reports: return "chart.xyaxis.line"
        case .settings: return "slider.horizontal.3"
        }
    }
}

#Preview {
    MainTabView(
        store: Store(initialState: MainTab.State()) {
            MainTab()
        }
    )
}
