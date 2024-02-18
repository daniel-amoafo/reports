// Created by Daniel Amoafo on 18/2/2024.

import SafariServices
import SwiftUI

struct SFSafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {

        return SFSafariViewController(url: url)
    }

    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: UIViewControllerRepresentableContext<SFSafariView>) {
        // No need to do anything
    }
}

#Preview {
    SFSafariView(url: URL(string: "www.apple.com")!)
}
