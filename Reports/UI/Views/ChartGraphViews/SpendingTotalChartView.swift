// Created by Daniel Amoafo on 21/4/2024.

import BudgetSystemService
import Charts
import IdentifiedCollections
import SwiftUI

struct SpendingTotalChartView: View {

    @State var selectedCategory: String?

    let transactions: IdentifiedArrayOf<BudgetSystemService.Transaction>
    let data: (
        groups: IdentifiedArrayOf<TabulatedDataItem>,
        categories: IdentifiedArrayOf<TabulatedDataItem>
    )

    init(transactions: IdentifiedArrayOf<BudgetSystemService.Transaction>) {
        self.transactions = Transaction.mock // transactions
        self.data = Self.makeTabulatedData(transactions: transactions)
        self.selectedCategory = nil
    }

    var body: some View {
        VStack(spacing: .Spacing.medium) {
            Chart(data.groups) { item in
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

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Text(Strings.categorized)
                        .typography(.title2Emphasized)
                        .foregroundStyle(Color(R.color.text.secondary))
                    Spacer()
                }
                .listRowTop()

                ForEach(data.groups) { item in
                    HStack {
                        Text(item.name)
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color(R.color.text.primary))
                        Spacer()
                        Text("\(item.value)")
                            .typography(.bodyEmphasized)
                            .foregroundStyle(Color(R.color.text.primary))
                    }
                    .listRow()
                }

                Text("")
                    .listRowBottom()
            }
            .backgroundShadow()
        }
    }
}

// MARK: -

extension SpendingTotalChartView {

    static func makeTabulatedData(transactions: IdentifiedArrayOf<BudgetSystemService.Transaction>) -> (
        groups: IdentifiedArrayOf<TabulatedDataItem>,
        categories: IdentifiedArrayOf<TabulatedDataItem>
    ) {
        var categoryGroups = IdentifiedArray<String, TabulatedDataItem>()
        var uncategorizedCategoryGroups = newUnCategorizedTabularDataItem()

        var categories = IdentifiedArray<String, TabulatedDataItem>()
        var uncategorizedCategories = newUnCategorizedTabularDataItem()
        categories.append(uncategorizedCategories)

        for transaction in transactions {
            makeCategoryGroupTabulatedDataItem(
                transaction: transaction,
                categoryGroups: &categoryGroups,
                uncategorized: &uncategorizedCategoryGroups
            )

            makeCategoryTabulatedDataItem(
                transaction: transaction,
                categories: &categories,
                uncategorized: &uncategorizedCategories
            )
        }

        if !uncategorizedCategoryGroups.value.isZero {
            categoryGroups.append(uncategorizedCategoryGroups)
        }
        return (categoryGroups, categories)
    }

    static func makeCategoryGroupTabulatedDataItem(
        transaction: BudgetSystemService.Transaction,
        categoryGroups: inout IdentifiedArrayOf<TabulatedDataItem>,
        uncategorized: inout TabulatedDataItem
    ) {
        if let categoryGroupId = transaction.categoryGroupId {
            var categoryGroup: TabulatedDataItem
            if let item = categoryGroups[id: categoryGroupId] {
                categoryGroup = item
            } else {
                categoryGroup = .init(
                    id: categoryGroupId,
                    name: transaction.categoryGroupName ?? "[Unexpected empty category group name]",
                    value: .zero
                )
                categoryGroups.append(categoryGroup)
            }
            categoryGroup.value = 1 + abs(transaction.money.amount)
        } else {
            uncategorized.value += abs(transaction.money.amount)
        }
    }

    static func makeCategoryTabulatedDataItem(
        transaction: BudgetSystemService.Transaction,
        categories: inout IdentifiedArrayOf<TabulatedDataItem>,
        uncategorized: inout TabulatedDataItem
    ) {
        if let categoryId = transaction.categoryId {
            var category: TabulatedDataItem
            if let item = categories[id: categoryId] {
                category = item
            } else {
                category = .init(
                    id: categoryId,
                    name: transaction.categoryGroupName ?? "[Unexpected category name]",
                    value: .zero
                )
                categories.append(category)
            }
            category.value += transaction.money.amount
        } else {
            uncategorized.value += transaction.money.amount
        }
    }

    static func newUnCategorizedTabularDataItem() -> TabulatedDataItem {
        .init(id: UUID().uuidString, name: Strings.uncategorized, value: .zero)
    }
}

struct TabulatedDataItem: Identifiable {

    let id: String
    let name: String
    var value: Decimal
}

private enum Strings {

    static let categorized = String(
        localized: "Categories",
        comment: "title for list of categories for the selected data set"
    )
    static let uncategorized = String(
        localized: "Uncategorized",
        comment: "Category title for transactions without a formal category"
    )
}

// MARK: -

#Preview {
    ScrollView {
        SpendingTotalChartView(transactions: Transaction.mock)
    }
    .contentMargins(.Spacing.medium)

}

private extension BudgetSystemService.Transaction {

    // TODO :- load this from sample json data
    static var mock: IdentifiedArrayOf<Self> {
        [
            .init(
                id: "T1",
                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
                money: .init(.init(-150.99), currency: .AUD),
                accountId: "A1",
                accountName: "First Account",
                categoryId: "C1",
                categoryName: "Groceries",
                categoryGroupId: "CG1",
                categoryGroupName: "Fixed Expenses",
                transferAccountId: nil,
                deleted: false
            ),
//            .init(
//                id: "T2",
//                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
//                money: .init(.init(-300.00), currency: .AUD),
//                accountId: "A1",
//                accountName: "First Account",
//                categoryId: "C2",
//                categoryName: "Rent",
//                categoryGroupId: "CG2",
//                categoryGroupName: "House Expenses",
//                transferAccountId: nil,
//                deleted: false
//            ),
            .init(
                id: "T3",
                date: Date.iso8601Formatter.date(from: "2024-02-01")!,
                money: .init(.init(-120.00), currency: .AUD),
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
                money: .init(.init(-50), currency: .AUD),
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
