// Created by Daniel Amoafo on 23/4/2024.

import BudgetSystemService
import Foundation
import IdentifiedCollections
import MoneyCommon

extension ReportChart {

    static let mock: ReportChart = Self.makeDefaultCharts()[0]
}

// MARK: - Account

extension IdentifiedArray where ID == Account.ID, Element == Account {

    static let mocks: Self = [
        .init(id: "01", name: "Everyday Account", deleted: false),
        .init(id: "02", name: "Acme Account", deleted: false),
        .init(id: "03", name: "Appleseed Account", deleted: false),
    ]
}

// MARK: - BudgetSummary

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

// MARK: - CategoryGroup

extension IdentifiedArray where Element == CategoryGroup, ID == CategoryGroup.ID {

    static let mocks: Self = [
        .init(
            id: "CG-FIX-EXP",
            name: "Fixed Expenses",
            hidden: false,
            deleted: false,
            categoryIds: ["CAT-RENT", "CAT-GROC"]
        ),
        .init(
            id: "CG-TRANS",
            name: "Transportation",
            hidden: false,
            deleted: false,
            categoryIds: ["CAT-TRAIN", "CAT-TAXI"]
        ),
    ]
}

// MARK: - Category

extension IdentifiedArray where Element == BudgetSystemService.Category, ID == BudgetSystemService.Category.ID {

    static let mocks: Self = [
        .init(
            id: "CAT-RENT",
            categoryGroupId: "CG-FIX-EXP",
            name: "Rent",
            hidden: false,
            note: nil,
            balance: Money(123.45, currency: .AUD),
            deleted: false
        ),
        .init(
            id: "CAT-TRAIN",
            categoryGroupId: "CG-TRANS",
            name: "Train Ticket",
            hidden: false,
            note: nil,
            balance: Money(40.50, currency: .AUD),
            deleted: false
        ),
        .init(
            id: "CAT-TAXI",
            categoryGroupId: "CG-TRANS",
            name: "Taxi / Uber",
            hidden: false,
            note: nil,
            balance: Money(20.00, currency: .AUD),
            deleted: false
        ),
        .init(
            id: "CAT-GROCERIES",
            categoryGroupId: "CG-FIX-EXP",
            name: "Groceries",
            hidden: false,
            note: nil,
            balance: Money(89.50, currency: .AUD),
            deleted: false
        ),
    ]
}

// MARK: - TransactionEntry

extension IdentifiedArray where Element == TransactionEntry, ID == TransactionEntry.ID {

    static let mocks: Self = [
        .init(
            id: "T1",
            date: Date.iso8601Formatter.date(from: "2024-02-01")!,
            money: Money(Decimal(-1_00_00), currency: .AUD),
            payeeName: "Woolworths",
            accountId: "A1",
            accountName: "Account First",
            categoryId: "CAT-GROC",
            categoryName: "Groceries",
            categoryGroupId: "CG-FIX-EXP",
            categoryGroupName: "Fixed Expenses",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T2",
            date: Date.iso8601Formatter.date(from: "2024-02-01")!,
            money: Money(Decimal(-5_00), currency: .AUD),
            payeeName: "Opal",
            accountId: "A1",
            accountName: "Account First",
            categoryId: "CAT-TRAIN",
            categoryName: "Train Ticket",
            categoryGroupId: "CG-TRANS",
            categoryGroupName: "Transport",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T3",
            date: Date.iso8601Formatter.date(from: "2024-03-05")!,
            money: Money(Decimal(-299_99), currency: .AUD),
            payeeName: "Landlord",
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "CAT-RENT",
            categoryName: "Rent",
            categoryGroupId: "CG-FIX-EXP",
            categoryGroupName: "Fixed Expenses",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T4",
            date: Date.iso8601Formatter.date(from: "2024-04-24")!,
            money: Money(Decimal(-37_60), currency: .AUD),
            payeeName: "Uber",
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "CAT-TAXI",
            categoryName: "Taxi / Uber",
            categoryGroupId: "CG-TRANS",
            categoryGroupName: "Transport",
            transferAccountId: nil,
            deleted: false
        ),
    ]
}

// MARK: - BudgetClient

extension BudgetClient {

    public static var preview: BudgetClient {
        .init(
            budgetSummaries: .mocks,
            accounts: .mocks,
            categoryGroups: .mocks,
            categories: .mocks,
            authorizationStatus: .loggedIn,
            selectedBudgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id
        )
    }

}
