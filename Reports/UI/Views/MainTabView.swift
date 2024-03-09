// Created by Daniel Amoafo on 8/3/2024.

import ComposableArchitecture
import SwiftUI

struct MainTab {

    enum Tab { case home, reports, settings }

    @ObservableState
    struct State: Equatable {
        var currentTab = Tab.home
    }

    enum Action {

    }
}

struct MainTabView: View {
    var body: some View {
        Text("Placeholder")
    }
}

#Preview {
    MainTabView()
}
