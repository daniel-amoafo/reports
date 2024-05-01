// Created by Daniel Amoafo on 24/4/2024.

import BudgetSystemService
import Foundation
import IdentifiedCollections
import MoneyCommon

struct TabulatedDataItem: Identifiable, Equatable {

    let id: String
    let name: String
    var value: Decimal
    let currency: Currency
}

// MARK: -

extension TabulatedDataItem {

    var valueFormatted: String {
        Money(value, currency: currency).amountFormatted
    }
}

// MARK: - static values

extension TabulatedDataItem {

    /// Iterates over a given transaction list mapping transactions into the their associated CategoryGroups
    /// & Category lists.
    /// The transaction's amount values are summed per each CategoryGroup / Category.
    static func makeCategoryValues(transactions: IdentifiedArrayOf<TransactionEntry>) -> (
        groups: IdentifiedArrayOf<TabulatedDataItem>,
        categories: IdentifiedArrayOf<TabulatedDataItem>
    ) {
        // Need to have at least one transaction otherwise, exit early.
        // Valid assumption that all transaction amounts will be of the same currency.
        guard let currency = transactions.first?.money.currency else {
            return ([], [])
        }

        var categoryGroups = IdentifiedArray<String, TabulatedDataItem>()
        var uncategorizedCategoryGroups = newUnCategorizedTabularDataItem(currency)

        var categories = IdentifiedArray<String, TabulatedDataItem>()
        var uncategorizedCategories = newUnCategorizedTabularDataItem(currency)
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

        // sort categoryGroups in decending order with lowest negative values taking precedence
        categoryGroups.sort { $0.value < $1.value }

        return (categoryGroups, categories)
    }

    static func makeCategoryGroupTabulatedDataItem(
        transaction: TransactionEntry,
        categoryGroups: inout IdentifiedArrayOf<TabulatedDataItem>,
        uncategorized: inout TabulatedDataItem
    ) {
        if let categoryGroupId = transaction.categoryGroupId {
            var categoryGroup: TabulatedDataItem
            if let item = categoryGroups[id: categoryGroupId] {
                categoryGroup = item
                categoryGroup.value += transaction.money.amount
                categoryGroups[id: categoryGroupId] = categoryGroup
            } else {
                categoryGroup = .init(
                    id: categoryGroupId,
                    name: transaction.categoryGroupName ?? "[Unexpected empty category group name]",
                    value: transaction.money.amount,
                    currency: transaction.money.currency
                )
                categoryGroups.append(categoryGroup)
            }
        } else {
            uncategorized.value += transaction.money.amount
        }
    }

    static func makeCategoryTabulatedDataItem(
        transaction: TransactionEntry,
        categories: inout IdentifiedArrayOf<TabulatedDataItem>,
        uncategorized: inout TabulatedDataItem
    ) {
        if let categoryId = transaction.categoryId {
            var category: TabulatedDataItem
            if let item = categories[id: categoryId] {
                category = item
                category.value += transaction.money.amount
                categories[id: categoryId] = category
            } else {
                category = .init(
                    id: categoryId,
                    name: transaction.categoryName ?? "[Unexpected category name]",
                    value: transaction.money.amount,
                    currency: transaction.money.currency
                )
                categories.append(category)
            }
        } else {
            uncategorized.value += transaction.money.amount
        }
    }

    static func newUnCategorizedTabularDataItem(_ currency: Currency) -> TabulatedDataItem {
        .init(id: UUID().uuidString, name: Strings.uncategorized, value: .zero, currency: currency)
    }
}

// MARK: -

private enum Strings {

    static let uncategorized = String(
        localized: "Uncategorized",
        comment: "Category title for transactions without a formal category"
    )
}
