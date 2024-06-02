// Created by Daniel Amoafo on 31/5/2024.

import BudgetSystemService
import ComposableArchitecture
import IdentifiedCollections
import SwiftUI

struct SelectAccountsView: View {

    @Bindable var store: StoreOf<SelectAccountsFeature>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Surface.primary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        activeAccountsView
                        closedAccountsView
                    }
                    .padding(.horizontal)
                }
            }
            .toolbar { toolbarTopLeading }
            .toolbar { toolbarTopTrailing }
        }
    }
}

private extension SelectAccountsView {

    var toolbarTopLeading: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Group {
                Button(Strings.selectAll) {
                    store.send(.selectAll, animation: .smooth)
                }
                .foregroundStyle(Color.Text.secondary)

                Text(" | ")

                Button(Strings.deselectAll) {
                    store.send(.deselectAll, animation: .smooth)
                }
            }
            .foregroundStyle(Color.Text.secondary)
        }
    }

    var toolbarTopTrailing: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(AppStrings.doneButtonTitle) {
                dismiss()
            }
            .foregroundStyle(Color.Text.primary)
        }
    }

    var activeAccountsView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(Strings.activeAccounts)
                    .typography(.title2Emphasized)
                    .foregroundStyle(Color.Text.secondary)
                    .padding(.top, .Spacing.pt24)
                Spacer()
                Button {
                    store.send(.toggleActiveAll, animation: .smooth)
                } label: {
                    Image(
                        systemName: store.isAllActiveEnabled ? "square.inset.filled" : "square"
                    )
                    .symbolRenderingMode(.hierarchical)
                }
                .padding(.trailing, .Spacing.pt12)
                .buttonStyle(.plain)
                .foregroundStyle(Color.Button.secondary)
            }
            .padding(.horizontal)

            SelectListView(
                items: store.activeAccounts,
                selectedItems: $store.displaySelectedIds,
                noSelectionAllowed: true,
                typography: .headlineEmphasized,
                showDoneButton: false
            )
        }
    }

    var closedAccountsView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(Strings.closedAccounts)
                    .typography(.title2Emphasized)
                    .foregroundStyle(Color.Text.secondary)
                    .padding(.top, .Spacing.pt24)
                Spacer()
                Button {
                    store.send(.toggleClosedAll, animation: .smooth)
                } label: {
                    Image(
                        systemName: store.isAllClosedEnabled ? "square.inset.filled" : "square"
                    )
                    .symbolRenderingMode(.hierarchical)
                }
                .padding(.trailing, .Spacing.pt12)
                .buttonStyle(.plain)
                .foregroundStyle(Color.Button.secondary)
            }
            .padding(.horizontal)

            SelectListView(
                items: store.closedAccounts,
                selectedItems: $store.displaySelectedIds,
                noSelectionAllowed: true,
                typography: .headlineEmphasized,
                showDoneButton: false
            )
        }
    }
}

private enum Strings {

    static let activeAccounts = String(
        localized: "Budget Accounts",
        comment: "Title for accounts that are currently open."
    )
    static let closedAccounts = String(
        localized: "Closed Accounts",
        comment: "Title for accounts that have been closed."
    )
    static let selectAll = String(
        localized: "Select All",
        comment: "button to select all accounts"
    )
    static let deselectAll = String(
        localized: "Select None",
        comment: "button to select deselect all accounts"
    )

}

#Preview {
    NavigationStack {
        SelectAccountsView(
            store: .init(
                initialState: .init(
                    budgetId: Factory.budgetId,
                    selectedIds: Shared(Set<String>())
                )
            ) {
                SelectAccountsFeature()
            }
        )
    }
}

private enum Factory {

    static var budgetId: String {
        IdentifiedArrayOf<BudgetSummary>.mocks[0].id
    }
}
