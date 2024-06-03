// Created by Daniel Amoafo on 23/4/2024.

import BudgetSystemService
import Foundation
import GRDB
import IdentifiedCollections
import MoneyCommon

private typealias Category = BudgetSystemService.Category
/**
 Mocked values on this page are used to populate SwiftUI Previews and sample data.
 */

enum MockData {

    static var budgetId: String { IdentifiedArrayOf<BudgetSummary>.mocks[0].id }

    static var accountId: String {
        IdentifiedArrayOf<Account>.mocks[0].id
    }

    static func insertSampleData(grdb: GRDBDatabase) throws {
        let budgets: IdentifiedArrayOf<BudgetSummary> = .mocks
        let accounts: IdentifiedArrayOf<Account> = .mocks
        let accountsClosed: IdentifiedArrayOf<Account> = .mocksClosed
        let categoryGroup: IdentifiedArrayOf<CategoryGroup> = .mocks
        let category: IdentifiedArrayOf<Category> = .mocks
        let transactions: IdentifiedArrayOf<TransactionEntry> = .mocks

        var records: [any PersistableRecord] = []
        records.append(contentsOf: budgets.elements)
        records.append(contentsOf: accounts.elements)
        records.append(contentsOf: accountsClosed.elements)
        records.append(contentsOf: categoryGroup.elements)
        records.append(contentsOf: category.elements)
        records.append(contentsOf: transactions.elements)

        try grdb.save(records: records)

        debugPrint("inserted mock records into db (\(records.count))")
    }

    static func insertConfigData(_ config: ConfigProvider) {
        config.selectedBudgetId = IdentifiedArrayOf<BudgetSummary>.mocks[0].id
    }
}

extension ReportChart {

    static let mock: ReportChart = Self.firstChart
}

// MARK: - Account

extension IdentifiedArrayOf where ID == Account.ID, Element == Account {

    static let mocks: Self = [
        .init(id: "01", budgetId: "Budget1", name: "Everyday Account", onBudget: true, closed: false, deleted: false),
        .init(id: "02", budgetId: "Budget1", name: "Acme Account", onBudget: true, closed: false, deleted: false),
        .init(id: "03", budgetId: "Budget1", name: "Appleseed Account", onBudget: true, closed: false, deleted: false),
        .init(
            id: "07",
            budgetId: "Budget2",
            name: "Budget Twwo Account",
            onBudget: true,
            closed: false,
            deleted: false
        ),
    ]

    static let mocksClosed: Self = [
        .init(id: "04", budgetId: "Budget1", name: "Grandpa Account", onBudget: true, closed: true, deleted: false),
        .init(id: "05", budgetId: "Budget1", name: "Nona Account", onBudget: true, closed: true, deleted: false),
        .init(id: "06", budgetId: "Budget1", name: "Jerry Account", onBudget: true, closed: true, deleted: false),
    ]
}

// MARK: - BudgetSummary

extension IdentifiedArrayOf where Element == BudgetSummary, ID == BudgetSummary.ID {

    static let mocks: Self = [
        .init(
            id: "Budget1",
            name: "Summary One",
            lastModifiedOn: "Yesterday",
            firstMonth: "March",
            lastMonth: "May",
            currency: .AUD,
            accounts: []
        ),
        .init(
            id: "Budget2",
            name: "Summary Two",
            lastModifiedOn: "Days ago",
            firstMonth: "April",
            lastMonth: "Jun",
            currency: .AUD,
            accounts: []
        ),
    ]
}

// MARK: - CategoryGroup

extension IdentifiedArrayOf where Element == CategoryGroup, ID == CategoryGroup.ID {

    static let mocks: Self = [
        .init(
            id: "CG-FIX-EXP",
            name: "Fixed Expenses",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
        .init(
            id: "CG-TRANS",
            name: "Transportation",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
        .init(
            id: "CG-ENTERTAINMENT",
            name: "Entertainment",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
    ]
}

// MARK: - Category

extension IdentifiedArray where Element == Category, ID == Category.ID {

    static let mocks: Self = [
        .init(
            id: "CAT-RENT",
            categoryGroupId: "CG-FIX-EXP",
            name: "Rent",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
        .init(
            id: "CAT-TRAIN",
            categoryGroupId: "CG-TRANS",
            name: "Train Ticket",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
        .init(
            id: "CAT-TAXI",
            categoryGroupId: "CG-TRANS",
            name: "Taxi / Uber",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
        .init(
            id: "CAT-GROCERIES",
            categoryGroupId: "CG-FIX-EXP",
            name: "Groceries",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
        .init(
            id: "CAT-MOVIES",
            categoryGroupId: "CG-ENTERTAINMENT",
            name: "Movies",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
        .init(
            id: "CAT-CONCERT",
            categoryGroupId: "CG-ENTERTAINMENT",
            name: "Concert",
            hidden: false,
            deleted: false,
            budgetId: "Budget1"
        ),
    ]
}

// MARK: - TransactionEntry

extension IdentifiedArray where Element == TransactionEntry, ID == TransactionEntry.ID {

    static let mocks: Self = [
        .init(
            id: "T1",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-02-01")!,
            rawAmount: -1_00_00,
            currencyCode: Currency.AUD.code,
            payeeName: "Woolworths",
            accountId: "A1",
            accountName: "Account First",
            categoryId: "CAT-GROC",
            categoryName: "Groceries",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T2",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-02-01")!,
            rawAmount: -5_00,
            currencyCode: Currency.AUD.code,
            payeeName: "Opal",
            accountId: "A1",
            accountName: "Account First",
            categoryId: "CAT-TRAIN",
            categoryName: "Train Ticket",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T3",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-03-05")!,
            rawAmount: -99_99,
            currencyCode: Currency.AUD.code,
            payeeName: "Landlord",
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "CAT-RENT",
            categoryName: "Rent",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T4",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-04-24")!,
            rawAmount: -37_60,
            currencyCode: Currency.AUD.code,
            payeeName: "Uber",
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "CAT-TAXI",
            categoryName: "Taxi / Uber",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T5",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-04-28")!,
            rawAmount: -20_00,
            currencyCode: Currency.AUD.code,
            payeeName: "IRH Party",
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "CAT-CONCERT",
            categoryName: "Concert",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T6",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-05-02")!,
            rawAmount: -60_00,
            currencyCode: Currency.AUD.code,
            payeeName: "The Midnights",
            accountId: "A3",
            accountName: "Account Third",
            categoryId: "CAT-CONCERT",
            categoryName: "Concert",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T7",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-03-11")!,
            rawAmount: -42_00,
            currencyCode: Currency.AUD.code,
            payeeName: "Hoyts",
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "CAT-Movies",
            categoryName: "Movies",
            transferAccountId: nil,
            deleted: false
        ),
    ]

    static let mocksTwo: Self = [
        .init(
            id: "T1",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-06-01")!,
            rawAmount: -5_00,
            currencyCode: Currency.AUD.code,
            payeeName: "Taxi",
            accountId: "A1",
            accountName: "Account First",
            categoryId: "CAT-TAXI",
            categoryName: "Taxi / Uber",
            transferAccountId: nil,
            deleted: false
        ),
        .init(
            id: "T2",
            budgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id,
            date: Date.iso8601utc.date(from: "2024-07-15")!,
            rawAmount: -10_50,
            currencyCode: Currency.AUD.code,
            payeeName: "Landlord",
            accountId: "A2",
            accountName: "Account Second",
            categoryId: "CAT-RENT",
            categoryName: "Rent",
            transferAccountId: nil,
            deleted: false
        ),
    ]
}

// MARK: - BudgetClient

extension BudgetClient {

    static var testsAndPreviews: BudgetClient {
        .init(
            budgetSummaries: .mocks,
            accounts: .mocks,
            categoryGroups: .mocks,
            categories: .mocks,
            transactions: .mocks,
            authorizationStatus: .loggedIn,
            selectedBudgetId: IdentifiedArrayOf<BudgetSummary>.mocks[0].id
        )
    }

}

// MARK: - SavedReport

extension SavedReport {

    static let mocks: [SavedReport] = {
        [
            .init(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                name: "Jan 1 2024 - Feb 28 2024",
                fromDate: "2024-01-01",
                toDate: "2024-02-28",
                chartId: ReportChart.firstChart.id,
                budgetId: MockData.budgetId,
                selectedAccountIds: MockData.accountId,
                lastModified: Date.iso8601utc.date(from: "2024-03-30T14:30")!
            ),
            .init(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
                name: "My Crazy Month",
                fromDate: "2024-03-05",
                toDate: "2024-04-04",
                chartId: ReportChart.firstChart.id,
                budgetId: MockData.budgetId,
                selectedAccountIds: MockData.accountId,
                lastModified: Date.iso8601utc.date(from: "2024-05-12T16:45")!
            ),
            .init(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
                name: "Fantastic Feb spending",
                fromDate: "2024-02-02",
                toDate: "2024-02-09",
                chartId: ReportChart.firstChart.id,
                budgetId: MockData.budgetId,
                selectedAccountIds: MockData.accountId,
                lastModified: Date.iso8601utc.date(from: "2024-02-12T08:45")!
            ),
            .init(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
                name: "May day",
                fromDate: "2024-05-01",
                toDate: "2024-05-09",
                chartId: ReportChart.firstChart.id,
                budgetId: MockData.budgetId,
                selectedAccountIds: MockData.accountId,
                lastModified: Date.iso8601utc.date(from: "2024-05-08T17:12")!
            ),
        ]
    }()
}
