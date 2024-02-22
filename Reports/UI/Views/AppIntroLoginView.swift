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

    @Dependency(\.openURL) var openURL

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .authorizeButtonTapped:
                if let url = createAuthorizeURL() {
                    state.showSafariBrowser = .init(url: url)
                }
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

    func createAuthorizeURL() -> URL? {
        let clientID = "2af5bad4b3d684eed0003a8f64bb5524c94ea728b13f0a93a48526e2171ee027"
        let redirectURI = "cw-reports://oauth"

        // .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!

        var ynabPath: String {
         "https://app.ynab.com/oauth/authorize?"
            + "client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=token&scope=read-only"
        }

        return .init(string: ynabPath)
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
        }
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
