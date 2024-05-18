// Created by Daniel Amoafo on 4/5/2024.

import BudgetSystemService
import ComposableArchitecture
@testable import Reports
import XCTest

final class ReportFeatureTests: XCTestCase {

    var store: TestStoreOf<ReportFeature>!
    // assume first entry is the .spendingByTotal chart type.
    let chart = ReportChart.firstChart
    let fromDate = Date.dateFormatter.date(from: "2024/05/01")!
    let toDate = Date.dateFormatter.date(from: "2024/05/23")!

    @MainActor
    func testSavingNewReport() async throws {
        store = createStoreWithNewReport()

        store.exhaustivity = .off
        // perform transaction fetch
        await store.send(\.inputFields.delegate.fetchedTransactions, .mocksTwo)
        await store.receive(\.chartDisplayed)

        store.exhaustivity = .on
        await store.send(.doneButtonTapped) {
            $0.confirmationDialog = Self.expectedNewConfirmationDialog
            $0.scrollToId = "GraphChartContainer"
        }

        await store.send(.confirmationDialog(.presented(.saveNewReport))) {
            $0.confirmationDialog = nil
            $0.showSavedReportNameAlert = true
            $0.savedReportName = "1 May 2024 - 23 May 2024"
        }

        let savedReportQuery = store.dependencies.savedReportQuery
        let initialSavedReportCount = try savedReportQuery.fetchCount(.init())
        await store.send(.savedReportName(shouldSave: true)) {
            $0.showSavedReportNameAlert = false
        }

        // Verify new report successfully persisted
        let updatedSavedReportCount = try savedReportQuery.fetchCount(.init())
        XCTAssertEqual(initialSavedReportCount + 1, updatedSavedReportCount)
    }

    @MainActor
    func testUpdatingSavedReport() async throws {
        let savedReport = createSavedReport()
        store = try createStoreWithSavedReport(savedReport)

        // Make a change to inputfield values. This indicates saved report needs updating
        let toDate = Date.now.advanced(by: 3600)
        await store.send(\.inputFields.updateToDateTapped, toDate) {
            $0.inputFields.toDate = toDate
        }

        await store.send(.doneButtonTapped) {
            $0.confirmationDialog = Self.expectedUpdateExistingConfirmationDialog
        }

        await store.send(.confirmationDialog(.presented(.updateExistingReport))) {
            $0.confirmationDialog = nil
            $0.showSavedReportNameAlert = true
            $0.savedReportName = "My First Report"
        }

        let initialLastModified = savedReport.lastModifield
        let initialToDate = savedReport.toDate
        await store.send(.savedReportName(shouldSave: true)) {
            $0.showSavedReportNameAlert = false
        }
        XCTAssertNotEqual(initialLastModified, savedReport.lastModifield)
        XCTAssertNotEqual(initialToDate, savedReport.toDate)
    }

    @MainActor
    func testFetchedTransactionsDisplaySelectedGraph() async throws {
        store = createStoreWithNewReport()

        // only interested in state changes made in this feature and ignore
        // the  transactions values set in the state object for ChartGraph.spendingByTotal
        store.exhaustivity = .off

        // When a input fields view returns fetched transactions.
        // The delegate updates the Reports view accordingly with the selected report type.
        XCTAssertNil(store.state.chartGraph)
        await store.send(\.inputFields.delegate.fetchedTransactions, .mocksTwo) {
            $0.scrollToId = nil
        }
        XCTAssertNotNil(store.state.chartGraph)
        guard case .spendingByTotal = store.state.chartGraph else {
            XCTFail("Expected \(ChartType.spendingByTotal) but got \(String(describing: store.state.chartGraph))")
            return
        }
        await store.receive(\.chartDisplayed) {
            $0.scrollToId = "GraphChartContainer"
        }
    }

    @MainActor
    func testTransactionHistoryUpdatedDestination() async throws {
        store = createStoreWithNewReport()

        // Given
        store.exhaustivity = .off
        await store.send(\.inputFields.delegate.fetchedTransactions, .mocksTwo)
        await store.receive(\.chartDisplayed)

        // When
        store.exhaustivity = .on
        await store.send(\.chartGraph.spendingByTotal.delegate.categoryTapped, .mocksTwo) {
            $0.destination = .transactionHistory(.init(transactions: .mocksTwo, title: "Taxi / Uber"))
        }
    }

}

private extension ReportFeatureTests {

    @MainActor
    private func createStoreWithNewReport() -> TestStoreOf<ReportFeature> {
        TestStore(
            initialState: try! .init(
                sourceData: .new(.init(chart: chart, fromDate: fromDate, toDate: toDate))
            )
        ) {
            ReportFeature()
        } withDependencies: {
            $0.savedReportQuery = .liveValue
        }
    }

    @MainActor
    func createStoreWithSavedReport(_ savedReport: SavedReport) throws -> TestStoreOf<ReportFeature> {
        @Dependency(\.database) var database
        let ctx = database.swiftData
        ctx.insert(savedReport)
        try ctx.save()

        return TestStore(
            initialState: try! .init(sourceData: .existing(savedReport))
        ) {
            ReportFeature()

        } withDependencies: {
            $0.savedReportQuery = .liveValue
        }
    }

    func createSavedReport() -> SavedReport {
        .init(
            name: "My First Report",
            fromDate: "2024-01-01",
            toDate: "2024-01-30",
            chartId: "spendingTotal",
            lastModified: Date.dateFormatter.date(from: "2024-02-02")!
        )
    }

}

// MARK: - Expected Data Values

// Extract to make tests call sites code more readable with verbose data structures given
// descriptive names below
private extension ReportFeatureTests {

    static var expectedNewConfirmationDialog: ConfirmationDialogState<ReportFeature.Action.ConfirmationDialog> {
        .init {
            TextState("")
        } actions: {
            ButtonState(action: .saveNewReport) {
                TextState("Save")
            }
            ButtonState(role: .destructive, action: .discard) {
                TextState("Discard")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("Save New Report?")
        }
    }

    static var expectedUpdateExistingConfirmationDialog:
    ConfirmationDialogState<ReportFeature.Action.ConfirmationDialog> {
        .init {
            TextState("")
        } actions: {
            ButtonState(action: .updateExistingReport) {
                TextState("Save")
            }
            ButtonState(role: .destructive, action: .discard) {
                TextState("Discard")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("Update Saved Report?")
        }
    }
}

private extension Array where Element == TransactionEntry {

    static let mocksTwo: Self = {
        IdentifiedArrayOf<TransactionEntry>.mocksTwo.elements
    }()
}
