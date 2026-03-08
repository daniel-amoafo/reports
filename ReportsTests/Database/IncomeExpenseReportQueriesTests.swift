// Created by Daniel Amoafo on 3/3/2026.

import BudgetSystemService
import GRDB
import MoneyCommon
@testable import Reports
import XCTest

final class IncomeExpenseReportQueriesTests: XCTestCase {

    var grdb: GRDBDatabase!

    override func setUpWithError() throws {
        grdb = try GRDBDatabase.makeMock(insertSampleData: true)
    }

    func testFetchReportData_CalculatesTotalsCorrectly() throws {
        // Given
        let budgetId = "Budget1"
        let fromDate = Date.iso8601utc.date(from: "2024-01-01")!
        let toDate = Date.iso8601utc.date(from: "2024-05-31")!

        // When
        let data = IncomeExpenseReportQueries.fetchReportData(
            budgetId: budgetId,
            fromDate: fromDate,
            toDate: toDate,
            accountIds: nil,
            categoryIds: nil,
            grdb: grdb
        )

        // Then
        // Based on MockDataStubs.swift:
        // T1: -100 (2024-01-01)
        // T2: -5 (2024-02-01)
        // T3: -99.99 (2024-03-05)
        // T4: -37.60 (2024-04-24)
        // T5: -20 (2024-04-28)
        // T6: -60 (2024-05-02)
        // T7: -42 (2024-03-11)
        // Total Expenses = 100 + 5 + 99.99 + 37.60 + 20 + 60 + 42 = 364.59
        // Total Income = 0 (No income in mock data yet)

        XCTAssertEqual(data.totalExpenses.amount, 364.59)
        XCTAssertEqual(data.totalIncome.amount, 0)
        XCTAssertEqual(data.netBalance.amount, -364.59)
    }

    func testFetchReportData_WithIncome() throws {
        // Given
        let budgetId = "Budget1"
        let fromDate = Date.iso8601utc.date(from: "2024-01-01")!
        let toDate = Date.iso8601utc.date(from: "2024-01-31")!

        // Add an income transaction
        let incomeTx = TransactionEntry(
            id: "T-INCOME",
            budgetId: budgetId,
            date: fromDate,
            rawAmount: 5000_00_0, // 5000.00
            currencyCode: "AUD",
            payeeName: "Employer",
            accountId: "A1",
            accountName: "Everyday Account",
            categoryId: "CAT-INCOME",
            categoryName: "Income",
            transferAccountId: nil,
            deleted: false
        )
        try grdb.save(record: incomeTx)

        // When
        let data = IncomeExpenseReportQueries.fetchReportData(
            budgetId: budgetId,
            fromDate: fromDate,
            toDate: toDate,
            accountIds: nil,
            categoryIds: nil,
            grdb: grdb
        )

        // Then
        XCTAssertEqual(data.totalIncome.amount, 5000.00)
        // T1 is also in Jan 2024: -100
        XCTAssertEqual(data.totalExpenses.amount, 100.00)
        XCTAssertEqual(data.netBalance.amount, 4900.00)
        XCTAssertEqual(data.incomeTrends.count, 1)
        XCTAssertEqual(data.expenseTrends.count, 1)
    }
}
