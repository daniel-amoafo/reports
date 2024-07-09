//  Created by Daniel Amoafo on 3/2/2024.

import ComposableArchitecture
import SwiftData
import SwiftUI

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
    }
}

private extension ReportsApp {

    private var rootView: some View {
        ZStack {
            Color.Surface.primary
                .ignoresSafeArea()
            switch store.authStatus {
            case .unknown:
                unknownStatusView

            case .loggedIn:
                if store.showOnboardingFlow, !store.didCompleteOnboarding {
                    OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))
                } else {
                    MainTabView(
                        store: store.scope(state: \.mainTab, action: \.mainTab)
                    )
                }
            case .loggedOut:
                AppIntroLoginView(
                    store: store.scope(state: \.appIntroLogin, action: \.appIntroLogin)
                )
            }
        }
    }

    var unknownStatusView: some View {
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
