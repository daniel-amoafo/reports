// Created by Daniel Amoafo on 1/5/2024.

import BudgetSystemService
import ComposableArchitecture
@testable import Reports
import XCTest

// final class ReportInputFeatureTests: XCTestCase {
//
//    var store: TestStoreOf<ReportInputFeature>!
//    let chart = ReportChart.firstChart
//    let startDate = Date.dateFormatter.date(from: "2024/01/01")!
//    let endDate = Date.dateFormatter.date(from: "2025/05/31")!
//
//    @MainActor
//    override func setUp() async throws {
//        store = TestStore(
//            initialState: .init(
//                chart: chart,
//                fromDate: startDate,
//                toDate: endDate
//            )
//        ) {
//            ReportInputFeature()
//        }
//    }

//    func testDateChangesLogic() async throws {
//
//        XCTAssertEqual(store.state.fromDate, startDate)
//        let newFromDate = Date.dateFormatter.date(from: "2025/01/01")!
//        await store.send(.updateFromDateTapped(newFromDate)) {
//            $0.fromDate = Date.dateFormatter.date(from: "2025/01/01")!
//        }
//
//        XCTAssertEqual(store.state.toDate, endDate)
//        let newToDate = Date.dateFormatter.date(from: "2025/03/30")!
//        await store.send(.updateToDateTapped(newToDate)) {
//            $0.toDate = Date.dateFormatter.date(from: "2025/03/30")!
//        }
//
//        // following date changes ensure dates cannot have invalid range
//        // i.e.where endDate is before start date
//        let fromDateAfterPreviousToDate = Date.dateFormatter.date(from: "2025/06/01")!
//        await store.send(.updateFromDateTapped(fromDateAfterPreviousToDate)) {
//            $0.fromDate = Date.dateFormatter.date(from: "2025/06/01")!
//            // toDate is updated to last day in the same month as fromDate
//            $0.toDate =  Date.dateFormatter.date(from: "2025/06/01")!.lastDayInMonth()
//        }
//
//        let afromDate = Date.dateFormatter.date(from: "2023/10/01")!
//        await store.send(.updateFromDateTapped(afromDate)) {
//            $0.fromDate = Date.dateFormatter.date(from: "2023/10/01")!
//        }
//
//        let beforeFromDate = Date.dateFormatter.date(from: "2022/07/01")!
//        await store.send(.updateToDateTapped(beforeFromDate)) {
//            $0.toDate = afromDate.lastDayInMonth()
//        }
//    }

//    func testStateChangeUpdates() async throws {
//        await store.send(.chartMoreInfoTapped) {
//            $0.showChartMoreInfo = true
//        }
//
//        XCTAssertEqual(store.state.showAccountList, false)
//        await store.send(.selectAccountRowTapped(true)) {
//            $0.showAccountList = true
//        }
//
//        // selected account values
//        XCTAssertNil(store.state.selectedAccountId)
//        XCTAssertNil(store.state.selectedAccountName)
//        XCTAssertFalse(store.state.isAccountSelected)
//        XCTAssertTrue(store.state.isRunReportDisabled)
//        await store.send(.didSelectAccountId("MyUpdatedAccountId")) {
//            $0.selectedAccountId = "MyUpdatedAccountId"
//        }
//        XCTAssertTrue(store.state.isAccountSelected)
//        XCTAssertFalse(store.state.isRunReportDisabled)
//
//        XCTAssertNil(store.state.accounts)
//        let expectedAllAccount = Account(
//            id: "CW_ALL_ACCOUNTS",
//            budgetId: "",
//            name: "All Accounts",
//            onBudget: true,
//            closed: false,
//            deleted: false
//        )
//        var expectedAccounts = IdentifiedArrayOf<Account>.mocks
//        // The buget client service populates accounts. An All Account entry will be added in the onAppear
//        // logic if state.account is not initialized with an account list.
//        expectedAccounts.insert(expectedAllAccount, at: 0)
//        await store.send(.onAppear) {
//            $0.selectedAccountId = expectedAllAccount.id
//            $0.accounts = expectedAccounts
//        }
//        XCTAssertEqual(store.state.selectedAccountName, expectedAllAccount.name)
//    }
//
// }
