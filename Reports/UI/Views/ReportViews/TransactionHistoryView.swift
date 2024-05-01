// Created by Daniel Amoafo on 30/4/2024.

import BudgetSystemService
import IdentifiedCollections
import SwiftUI

struct TransactionHistoryView: View {

    private let sections: IdentifiedArrayOf<SectionData>

    init(transactions: [TransactionEntry]) {
        sections = Self.mapToSectionData(transactions)
    }

    var body: some View {
        ZStack {
            Color.Surface.primary
                .ignoresSafeArea()
            if sections.isEmpty {
                noTransactions
            } else {
                transactionsList
            }
        }
    }

}

private extension TransactionHistoryView {

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

    var transactionsList: some View {
        List {
            ForEach(sections) { section in
                sectionView(for: section)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    func sectionView(for section: SectionData) -> some View {
        Section {
            ForEach(section.items) { item in
                rowView(for: item)
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

    func rowView(for item: TransactionEntry) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: .Spacing.pt4) {
                    Text(item.payeeName ?? "[No Payee Details]")
                        .typography(.headlineEmphasized)
                        .foregroundStyle(Color.Text.primary)
                    Text(item.categoryName ?? "[No Category Name]")
                        .typography(.bodyEmphasized)
                        .foregroundStyle(Color.Text.secondary)
                }
                Spacer()
                Text(item.amountFormatted())
                    .typography(.headlineEmphasized)
            }
            .padding(.horizontal)
            .padding(.vertical, .Spacing.pt8)
            HorizontalDivider()
        }
    }

    static func mapToSectionData(_ transactions: [TransactionEntry]) -> IdentifiedArrayOf<SectionData> {
        let sortedByDateAndAmount = transactions.sorted {
            return ($0.date, $0.money) < ($1.date, $1.money)
        }

        return sortedByDateAndAmount.reduce(into: IdentifiedArrayOf<SectionData>()) { dict, entry in
            let title = entry.dateFormatedLong
            if var section = dict[id: title] {
                section.items.append(entry)
                dict[id: title] = section
            } else {
                dict[id: title] = .init(title: title, items: [entry])
            }
       }
    }
}

private enum Strings {
    static let noTransactioinsText = String(
        localized: "No transactions found.", comment: "displayed when not transactions were"
    )
}

/// A simple struct to group transactions by date.
/// This allows the entries to be represented as sections in a list.
private struct SectionData: Identifiable {
    let title: String
    var items: [TransactionEntry]
    var id: String { title }
}

// MARK: - Preview

#Preview("Transactions Listed") {
    TransactionHistoryView(transactions: IdentifiedArrayOf<TransactionEntry>.mocks.elements)
}

#Preview("No Transactions") {
    TransactionHistoryView(transactions: [])
}
