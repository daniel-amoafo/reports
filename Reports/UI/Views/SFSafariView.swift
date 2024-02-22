// Created by Daniel Amoafo on 18/2/2024.

import ComposableArchitecture
import SafariServices
import SwiftUI

@Reducer
struct SFSafari {

    @ObservableState
    struct State: Equatable {
        let url: URL
    }

    enum Action {}
}

struct SFSafariView: UIViewControllerRepresentable {
    @Bindable var store: StoreOf<SFSafari>

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {

        return SFSafariViewController(url: self.store.url)
    }

    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: UIViewControllerRepresentableContext<SFSafariView>) {
        // No need to do anything
    }
}

#Preview {
    SFSafariView(
        store: Store(
            initialState: SFSafari.State(url: URL(string: "www.apple.com")!), reducer: { SFSafari() }
        )
    )
}
