// Created by Daniel Amoafo on 23/4/2024.

import BudgetSystemService
import Foundation
import IdentifiedCollections
import MoneyCommon

extension ReportChart {

    static let mock: ReportChart = Self.makeDefaultCharts()[0]
}

extension IdentifiedArray where ID == Account.ID, Element == Account {

    static let mocks: Self = [
        .init(id: "01", name: "Everyday Account", deleted: false),
        .init(id: "02", name: "Acme Account", deleted: false),
        .init(id: "03", name: "Appleseed Account", deleted: false),
    ]
}

extension IdentifiedArray where Element == BudgetSummary, ID == BudgetSummary.ID {

    static let mocks: Self = [
        .init(
            id: "Budget1",
            name: "Summary One",
            lastModifiedOn: "Yesterday",
            firstMonth: "March",
            lastMonth: "May",
            currency: .AUD
        ),
        .init(
            id: "Budget2",
            name: "Summary Two",
            lastModifiedOn: "Days ago",
            firstMonth: "April",
            lastMonth: "Jun",
            currency: .AUD
        ),
    ]
}

extension IdentifiedArray where Element == CategoryGroup, ID == CategoryGroup.ID {

    static let mocks: Self = [
        .init(id: "CG1", name: "Fixed Expenses", hidden: false, deleted: false, categoryIds: ["CAT1"]),
        .init(id: "CG2", name: "Transportation", hidden: false, deleted: false, categoryIds: ["CAT2", "CAT3"]),
    ]
}

extension IdentifiedArray where Element == BudgetSystemService.Category, ID == BudgetSystemService.Category.ID {

    static let mocks: Self = [
        .init(
            id: "CAT1",
            categoryGroupId: "GC1",
            name: "Rent",
            hidden: false,
            note: nil,
            balance: Money(123.45, currency: .AUD),
            deleted: false
        ),
        .init(
            id: "CAT2",
            categoryGroupId: "GC2",
            name: "Train Ticket",
            hidden: false,
            note: nil,
            balance: Money(40.50, currency: .AUD),
            deleted: false
        ),
        .init(
            id: "CAT3",
            categoryGroupId: "GC2",
            name: "Taxi / Uber",
            hidden: false,
            note: nil,
            balance: Money(20.00, currency: .AUD),
            deleted: false
        ),
    ]
}

extension IdentifiedArray where Element == TransactionEntry, ID == TransactionEntry.ID {

    static let mocks: Self = [
        .init(
            id: "T1",
            date: Date.iso8601Formatter.date(from: "2024-02-01")!,
            money: Money(Decimal(-100), currency: .AUD),
            accountId: "A1",
            accountName: "Account First",
            categoryId: "C1",
            categoryName: "Groceries",
            categoryGroupId: "CG01",
            categoryGroupName: "Acme",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T2",
            date: Date.iso8601Formatter.date(from: "2024-03-04")!,
            money: Money(Decimal(-123.45), currency: .AUD),
            accountId: "A1",
            accountName: "Account First",
            categoryId: "C2",
            categoryName: "Electricity Bill",
            categoryGroupId: "CG02",
            categoryGroupName: "Bills",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T3",
            date: Date.iso8601Formatter.date(from: "2024-04-05")!,
            money: Money(Decimal(-299.99), currency: .AUD),
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "C3",
            categoryName: "Rent",
            categoryGroupId: "CG03",
            categoryGroupName: "Home Expenses",
            transferAccountId: nil,
            deleted: false
        ),
    ]
}

// MARK: - BudgetClient

extension BudgetClient {

    public static var preview: BudgetClient {
        .init(
            provider: .preview,
            selectedBudgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            authorizationStatus: .loggedIn
        )
    }

}

extension BudgetProvider {

    public static var preview: Self {
        .init {
            IdentifiedArrayOf<BudgetSummary>.mocks.elements
        } fetchAccounts: { _ in
            IdentifiedArrayOf<Account>.mocks.elements
        } fetchCategoryValues: { _ in
            (IdentifiedArrayOf<CategoryGroup>.mocks.elements,
             IdentifiedArrayOf<BudgetSystemService.Category>.mocks.elements)
        } fetchTransactions: { _ in
            IdentifiedArrayOf<TransactionEntry>.mocks.elements
        }
    }
}
