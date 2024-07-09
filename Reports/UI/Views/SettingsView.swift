// Created by Daniel Amoafo on 10/3/2024.

import Dependencies
import SwiftUI

struct SettingsView: View {

    var body: some View {
        Button {
            Task {
                @Dependency(\.budgetClient) var budgetClient
                await budgetClient.logout()
            }
        } label: {
            Text("Logout")
        }
        .buttonStyle(.kleonPrimary)
        .containerRelativeFrame(.horizontal) { length, _ in
            length * 0.7
        }
        .navigationTitle(Text(Strings.title))
    }
}

// MARK: Strings

private enum Strings {
    static let title = String(localized: "Settings ⚙️", comment: "The settings screen main title")
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SettingsView()
    }
}
