// Created by Daniel Amoafo on 18/2/2024.

import ComposableArchitecture
import SwiftUI

@Reducer
struct AppIntroLogin {

    @ObservableState
    struct State: Equatable {
        @Presents var showSafariBrowser: SFSafari.State?
    }

    enum Action {
        case authorizeButtonTapped
        case showSafariBrowser(PresentationAction<SFSafari.Action>)
    }

    @Dependency(\.configProvider) var configProvider

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .authorizeButtonTapped:
                state.showSafariBrowser = .init(url: createAuthorizeURL())
                return .none
            case .showSafariBrowser:
                return .none
            }
        }
        .ifLet(\.$showSafariBrowser, action: \.showSafariBrowser) {
          SFSafari()
        }
    }
}

private extension AppIntroLogin {

    func createAuthorizeURL() -> URL {
        guard let oauthUrl = URL(string: configProvider.oauthPath) else {
            fatalError("Unable to generate ouath path url - \(configProvider.oauthPath)")
        }
        return oauthUrl
    }
}

// MARK: -

struct AppIntroLoginView: View {
    @Bindable var store: StoreOf<AppIntroLogin>

    var body: some View {
        VStack {
            Button("Login into YNAB") {
                self.store.send(.authorizeButtonTapped)
            }
            .buttonStyle(.kleonPrimary)
            .containerRelativeFrame(.horizontal) { size, _ in
                size * 0.7
            }
        }
        .padding(.horizontal)
        .sheet(
            item: $store.scope(
                state: \.showSafariBrowser,
                action: \.showSafariBrowser
            )
        ) { store in
            SFSafariView(store: store)
        }
    }
}

#Preview {
    AppIntroLoginView(store: Store(initialState: AppIntroLogin.State(), reducer: {
        AppIntroLogin()
    }))
}
