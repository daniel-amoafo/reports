// Created by Daniel Amoafo on 1/5/2024.

import BudgetSystemService
import ComposableArchitecture
@testable import Reports
import XCTest

final class ReportInputFeatureTests: XCTestCase {

    var store: TestStoreOf<ReportInputFeature>!
    let chart = ReportChart.firstChart
    let startDate = Date.dateFormatter.date(from: "2024/01/01")!
    let endDate = Date.dateFormatter.date(from: "2024/05/30")!

    @MainActor
    override func setUp() async throws {
        store = TestStore(
            initialState: .init(
                chart: chart,
                fromDate: startDate,
                toDate: endDate
            )
        ) {
            ReportInputFeature()
        }
    }

    func testStateChangesUpdate() async throws {
        await store.send(.chartMoreInfoTapped) {
            $0.showChartMoreInfo = true
        }

        XCTAssertEqual(store.state.fromDate, startDate)
        let newFromDate = Date.dateFormatter.date(from: "2025/01/01")!
        await store.send(.updateFromDateTapped(newFromDate)) {
            $0.fromDate = Date.dateFormatter.date(from: "2025/01/01")!
        }

        XCTAssertEqual(store.state.toDate, endDate)
        let newToDate = Date.dateFormatter.date(from: "2025/03/30")!
        await store.send(.updateToDateTapped(newToDate)) {
            $0.toDate = Date.dateFormatter.date(from: "2025/03/30")!
        }

        XCTAssertEqual(store.state.showAccountList, false)
        await store.send(.selectAccountRowTapped(true)) {
            $0.showAccountList = true
        }

        // selected account values
        XCTAssertNil(store.state.selectedAccountId)
        XCTAssertNil(store.state.selectedAccountName)
        XCTAssertFalse(store.state.isAccountSelected)
        XCTAssertTrue(store.state.isRunReportDisabled)
        await store.send(.didSelectAccountId("MyUpdatedAccountId")) {
            $0.selectedAccountId = "MyUpdatedAccountId"
        }
        XCTAssertTrue(store.state.isAccountSelected)
        XCTAssertFalse(store.state.isRunReportDisabled)

        XCTAssertNil(store.state.accounts)
        let expectedAllAccount = Account(id: "CW_ALL_ACCOUNTS", name: "All Accounts", deleted: false)
        var expectedAccounts = IdentifiedArrayOf<Account>.mocks
        // The buget client service populates accounts. An All Account entry will be added in the onAppear
        // logic if state.account is not initialized with an account list.
        expectedAccounts.insert(expectedAllAccount, at: 0)
        await store.send(.onAppear) {
            $0.selectedAccountId = expectedAllAccount.id
            $0.accounts = expectedAccounts
        }
        XCTAssertEqual(store.state.selectedAccountName, expectedAllAccount.name)
    }

    func testFetchTransactions() async throws {
        XCTAssertFalse(store.state.isReportFetching)
        XCTAssertEqual(store.state.fetchStatus, .ready)
        await store.send(.runReportTapped) {
            $0.fetchStatus = .fetching
        }
        XCTAssertTrue(store.state.isReportFetching)
        XCTAssertTrue(store.state.isReportFetchingLoadingOrErrored)

        await store.receive(\.fetchedTransactionsReponse) {
            $0.fetchStatus = .ready
        }
        await store.receive(\.delegate.fetchedTransactions)
        XCTAssertFalse(store.state.isReportFetching)
        XCTAssertFalse(store.state.isReportFetchingLoadingOrErrored)
    }

    func testFetchTransactionsNoResults() async throws {
        // change the date range to be outside of the mock tranaction entry values
        // this will filter out all transactions return an empty list return an error - no results
        let fromDate = Date.dateFormatter.date(from: "2023/01/01")!
        await store.send(\.updateFromDateTapped, fromDate) {
            $0.fromDate = fromDate
        }
        let toDate = Date.dateFormatter.date(from: "2023/06/06")!
        await store.send(\.updateToDateTapped, toDate) {
            $0.toDate = toDate
        }
        await store.send(.runReportTapped) {
            $0.fetchStatus = .fetching
        }
        await store.receive(\.fetchedTransactionsReponse) {
            $0.fetchStatus = .error(.noResults)
        }
        XCTAssertTrue(store.state.isReportFetchingLoadingOrErrored)
    }
}
