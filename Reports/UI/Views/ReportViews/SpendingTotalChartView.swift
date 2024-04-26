// Created by Daniel Amoafo on 21/4/2024.

import BudgetSystemService
import Charts
import ComposableArchitecture
import MoneyCommon
import SwiftUI

// MARK: - Reducer

@Reducer
struct SpendingTotalChartFeature {

    @ObservableState
    struct State: Equatable {
        let transactions: IdentifiedArrayOf<TransactionEntry>
        var contentType: SpendingTotalChartFeature.ContentType = .categoryGroup
        fileprivate let categoryGroups: IdentifiedArrayOf<TabulatedDataItem>
        fileprivate let categories: IdentifiedArrayOf<TabulatedDataItem>

        init(transactions: IdentifiedArrayOf<TransactionEntry>) {
            self.transactions = transactions
            let (groups, categories) = TabulatedDataItem.makeCategoryValues(transactions: transactions)
            self.categoryGroups = groups
            self.categories = categories
        }
    }

    enum ContentType: Equatable {
        case categoryGroup
        case category(id: String, isOnlyAllowed: Bool)
    }

    enum Action {
       // rowTapped
    }
}

// MARK: - View

struct SpendingTotalChartView: View {

    @Bindable var store: StoreOf<SpendingTotalChartFeature>

    var body: some View {
        VStack(spacing: .Spacing.pt24) {
            chart

            Divider()

            listRows
        }
    }

    private var chart: some View {
        VStack(spacing: .Spacing.pt16) {
            Chart(store.categoryGroups) { item in
                SectorMark(
                    angle: .value("Value", abs(item.value)),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(20),
                    angularInset: 1
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Name", item.name))
            }
            .chartLegend(.visible)
            .chartLegend(alignment: .bottom)
            .aspectRatio(contentMode: .fit)
        }
    }

    private var listRows: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(Strings.categorized)
                    .typography(.title2Emphasized)
                    .foregroundStyle(Color(R.color.text.secondary))
                Spacer()
            }
            .listRowTop()

            // Category rows
            ForEach(store.categoryGroups) { item in
                Button {
                    // store.send()
                } label: {
                    HStack {
                        Text(item.name)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color(R.color.text.primary))
                        Spacer()
                        Text(item.valueFormatted)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color(R.color.text.primary))
                    }
                }
                .buttonStyle(.listRow)
            }

            // Footer row
            Text("")
                .listRowBottom()
        }
        .backgroundShadow()
    }
}

// MARK: -

private enum Strings {

    static let categorized = String(
        localized: "Categories",
        comment: "title for list of categories for the selected data set"
    )

}

// MARK: -

#Preview {
    ScrollView {
        SpendingTotalChartView(
            store: .init(
                initialState: .init(transactions: .mock),
                reducer: { SpendingTotalChartFeature() }
            )
        )
    }
    .contentMargins(.Spacing.pt16)
}

private extension IdentifiedArray where Element == TransactionEntry, ID == TransactionEntry.ID {

    static var mock: Self {
        [
            .init(
                id: "T1",
                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
                money: .init(.init(-1599), currency: .AUD),
                accountId: "A1",
                accountName: "First Account",
                categoryId: "C1",
                categoryName: "Groceries",
                categoryGroupId: "CG1",
                categoryGroupName: "Fixed Expenses",
                transferAccountId: nil,
                deleted: false
            ),
            .init(
                id: "T2",
                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
                money: .init(.init(-3000), currency: .AUD),
                accountId: "A1",
                accountName: "First Account",
                categoryId: "C2",
                categoryName: "Rent",
                categoryGroupId: "CG2",
                categoryGroupName: "House Expenses",
                transferAccountId: nil,
                deleted: false
            ),
            .init(
                id: "T3",
                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
                money: .init(.init(-1200), currency: .AUD),
                accountId: "A1",
                accountName: "First Account",
                categoryId: "C2",
                categoryName: "Rent",
                categoryGroupId: "CG2",
                categoryGroupName: "House Expenses",
                transferAccountId: nil,
                deleted: false
            ),
            .init(
                id: "T4",
                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
                money: .init(.init(-500), currency: .AUD),
                accountId: "A1",
                accountName: "First Account",
                categoryId: "C3",
                categoryName: "Electricty Bill",
                categoryGroupId: "CG1",
                categoryGroupName: "Fixed Expenses",
                transferAccountId: nil,
                deleted: false
            ),
        ]
    }
}
