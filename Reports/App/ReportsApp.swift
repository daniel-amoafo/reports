//  Created by Daniel Amoafo on 3/2/2024.

import ComposableArchitecture
import SwiftUI

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
                    Text("Tab View - Customer Logged In 🎉")
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
