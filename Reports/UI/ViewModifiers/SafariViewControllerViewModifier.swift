// Created by Daniel Amoafo on 18/2/2024.

import SwiftUI

extension View {
    /// Monitor the `openURL` environment variable and handle them in-app instead of via
    /// the external web browser.
    /// Uses the `SafariViewWrapper` which will present the URL in a `SFSafariViewController`.
    func handleOpenURLInApp() -> some View {
        modifier(SafariViewControllerViewModifier())
    }
}

/// Monitors the `openURL` environment variable and handles them in-app instead of via
/// the external web browser.
private struct SafariViewControllerViewModifier: ViewModifier {
    @State private var urlToOpen: URL?

    func body(content: Content) -> some View {
        content
            .environment(
                \.openURL,
                 OpenURLAction { url in
                /// Catch any URLs that are about to be opened in an external browser.
                /// Instead, handle them here and store the URL to reopen in our sheet.
                     urlToOpen = url
                     return .handled
                 }
            )
            .sheet(
                isPresented: $urlToOpen.mappedToBool(),
                onDismiss: {
                    urlToOpen = nil
                }, content: {
                   EmptyView()
                }
            )
    }
}
