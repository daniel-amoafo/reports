// Created by Daniel Amoafo on 1/5/2024.

import BudgetSystemService
import ComposableArchitecture
@testable import Reports
import XCTest

final class ReportInputFeatureTests: XCTestCase {

    var store: TestStoreOf<ReportInputFeature>!

    @MainActor
    override func setUp() async throws {
        @Shared(.wsValues) var workspaceValues
        workspaceValues.accountsOnBudgetNames = Factory.accountIdAndName

        store = Factory.createTestStore()
    }

    @MainActor
    func testChartMoreInfoTapped() async throws {
        await store.send(.chartMoreInfoTapped) {
            $0.showChartMoreInfo = true
        }
    }

    @MainActor
    func testDateRangeIsNotInversed() async throws {
        XCTAssertEqual(store.state.fromDate, Factory.startDate)
        let newFromDate = Date.local.date(from: "2025/01/01")!
        await store.send(.updateFromDateTapped(newFromDate)) {
            $0.fromDate = Date.local.date(from: "2025/01/01")!
        }

        XCTAssertEqual(store.state.toDate, Factory.endDate)
        let newToDate = Date.local.date(from: "2025/03/30")!
        await store.send(.updateToDateTapped(newToDate)) {
            $0.toDate = Date.local.date(from: "2025/03/30")!
        }

        // following date changes ensure dates cannot have invalid range
        // i.e. where endDate is before start date
        let fromDateIsAfterToDate = Date.local.date(from: "2025/06/01")!
        await store.send(.updateFromDateTapped(fromDateIsAfterToDate)) {
            $0.fromDate = Date.local.date(from: "2025/06/01")!
            // toDate is updated to last day in the same month as fromDate
            $0.toDate = Date.local.date(from: "2025/06/01")!.lastDayInMonth()
        }

        let afromDate = Date.local.date(from: "2023/10/01")!
        await store.send(.updateFromDateTapped(afromDate)) {
            $0.fromDate = Date.local.date(from: "2023/10/01")!
        }

        let beforeFromDate = Date.local.date(from: "2022/07/01")!
        await store.send(.updateToDateTapped(beforeFromDate)) {
            $0.toDate = afromDate.lastDayInMonth()
        }
    }

    @MainActor
    func testSelectAccounts() async throws {
        // Given

        await store.send(.selectAccountRowTapped) {
            $0.selectedAccounts = .init(budgetId: Factory.budgetId)
        }

        // selected account values
        XCTAssertNil(store.state.selectedAccountIds)
        XCTAssertTrue(store.state.selectedAccountIdsSet.isEmpty)
        XCTAssertFalse(store.state.isAccountSelected)
        XCTAssertTrue(store.state.isRunReportDisabled)

        // WHEN
        // update the shared workspace selected Account ids. This should be reflected back in state model
        store.state.workspaceValues.updateSelectedAccountIds(ids: "account2ID,account1ID")

        // verify
        XCTAssertNotNil(store.state.selectedAccountIds)
        XCTAssertEqual(store.state.selectedAccountIdsSet.count, 2)
        XCTAssertTrue(store.state.isAccountSelected)
        XCTAssertFalse(store.state.isRunReportDisabled)
        XCTAssertEqual(store.state.selectedAccountNames, "First Account, Second Account")
    }

 }

// MARK: - Factory

private enum Factory {

    static let chart = ReportChart.firstChart
    static let startDate = Date.local.date(from: "2024/01/01")!
    static let endDate = Date.local.date(from: "2025/05/31")!
    static let budgetId = "Budget1ID"
    static let accountIdAndName = [
        "account1ID": "First Account",
        "account2ID": "Second Account",
        "account3ID": "Third Account",
    ]

    static func createTestStore(
        chart: ReportChart = Factory.chart,
        budgetId: String = Factory.budgetId,
        fromDate: Date = Factory.startDate,
        toDate: Date = Factory.endDate,
        selectedAccountIds: String? = nil
    ) -> TestStoreOf<ReportInputFeature> {
        TestStore(
            initialState: .init(
                chart: Factory.chart,
                budgetId: Factory.budgetId,
                fromDate: Factory.startDate,
                toDate: Factory.endDate,
                selectedAccountIds: selectedAccountIds
            )
        ) {
            ReportInputFeature()
        }
    }

}
