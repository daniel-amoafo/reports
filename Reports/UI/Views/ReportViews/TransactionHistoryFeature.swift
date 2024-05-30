// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct TransactionHistoryFeature {

    @ObservableState
    struct State: Equatable {
        let title: String?
        let sections: IdentifiedArrayOf<SectionData>

        init(transactions: [TransactionEntry], title: String?) {
            self.sections = Self.mapToSectionData(transactions)
            self.title = title
        }

        fileprivate static func mapToSectionData(_ transactions: [TransactionEntry]) -> IdentifiedArrayOf<SectionData> {
            // transactions by date followed by money amount
            let sortedByDateAndAmount = transactions.sorted {
                return ($0.date, $0.money) < ($1.date, $1.money)
            }

            return sortedByDateAndAmount.reduce(into: IdentifiedArrayOf<SectionData>()) { dict, entry in
                let title = entry.dateFormatedLong
                if var section = dict[id: title] {
                    section.entries.append(entry)
                    dict[id: title] = section
                } else {
                    dict[id: title] = .init(title: title, entries: [entry])
                }
            }
        }
    }
}

/// A simple struct to group transactions by date.
/// This allows the entries to be represented as sections in a list.
struct SectionData: Identifiable, Equatable {
    let title: String
    var entries: [TransactionEntry]
    var id: String { title }
}
