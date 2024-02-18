// Created by Daniel Amoafo on 18/2/2024.

import SwiftUI

struct AppIntroLogin: View {

    let clientID = "2af5bad4b3d684eed0003a8f64bb5524c94ea728b13f0a93a48526e2171ee027"
    let redirectURI = "cw-reports://oauth"

    // .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!

    var ynabPath: String {
     "https://app.ynab.com/oauth/authorize?"
        + "client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=token&scope=read-only"
    }

    var body: some View {
        VStack {
            Link("Login into YNAB", destination: URL(string: ynabPath)!)
        }
        .handleOpenURLInApp()
    }
}

#Preview {
    AppIntroLogin()
}
