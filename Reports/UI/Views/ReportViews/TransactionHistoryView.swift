// Created by Daniel Amoafo on 30/4/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

struct TransactionHistoryView: View {

    var store: StoreOf<TransactionHistoryFeature>

    var body: some View {
        ZStack {
            Color.Surface.primary
                .ignoresSafeArea()
            if store.sections.isEmpty {
                noTransactions
            } else {
                transactionsList
            }
        }
    }
}

private extension TransactionHistoryView {

    var transactionsList: some View {
        List {
            headerView

            // Category Sections
            ForEach(store.sections) { section in
                sectionView(for: section)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    var headerView: some View {
        if let title = store.title {
            Section {
                Text(title)
                    .typography(.title2Emphasized)
                    .foregroundStyle(Color.Text.secondary)
                    .padding(.horizontal)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
        }
    }

    func sectionView(for section: SectionData) -> some View {
        Section {
            ForEach(section.entries) { entry in
                rowView(for: entry)
            }
        } header: {
            Text(section.title)
                .typography(.subheadlineEmphasized)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .background(Color.Surface.sectionHeader)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(.zero)
    }

    func rowView(for entry: TransactionEntry) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: .Spacing.pt4) {
                    Text(entry.payeeName ?? "[No Payee Details]")
                        .typography(.headlineEmphasized)
                        .foregroundStyle(Color.Text.primary)
                    Text(entry.accountName)
                        .typography(.bodyEmphasized)
                        .foregroundStyle(Color.Text.secondary)
                }
                Spacer()
                Text(entry.amountFormatted)
                    .typography(.headlineEmphasized)
            }
            .padding(.horizontal)
            .padding(.vertical, .Spacing.pt8)
            HorizontalDivider()
        }
    }

    var noTransactions: some View {
        VStack(spacing: .Spacing.pt16) {
            ZStack {
                Image(systemName: "square.dashed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.Text.secondary)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.4
                    }

                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.Surface.sectionHeader)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.2
                    }
                    .fontWeight(.bold)
            }

            Text(Strings.noTransactioinsText)
                .typography(.title3Emphasized)
                .foregroundStyle(Color.Text.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}

// MARK: -

private enum Strings {
    static let noTransactioinsText = String(
        localized: "No transactions found.", comment: "displayed when not transactions were"
    )
}

// MARK: - Previews

#Preview("Transactions Listed") {
    NavigationStack {
        TransactionHistoryView(
            store: .init(initialState: TransactionHistoryFeature.mockState) {
                TransactionHistoryFeature()
            }
        )
    }
}

#Preview("No Transactions") {
    NavigationStack {
        TransactionHistoryView(
            store: .init(initialState: TransactionHistoryFeature.mockStateNoTransactions) {
                TransactionHistoryFeature()
            }
        )
    }
}

private extension TransactionHistoryFeature {

    static var mockState: TransactionHistoryFeature.State {
        .init(transactions: IdentifiedArrayOf<TransactionEntry>.mocks.elements, title: "Groceries")
    }

    static var mockStateNoTransactions: TransactionHistoryFeature.State {
        .init(transactions: [], title: "Entertianment")
    }
}
