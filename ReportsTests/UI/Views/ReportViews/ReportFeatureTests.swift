// Created by Daniel Amoafo on 4/5/2024.

import BudgetSystemService
import ComposableArchitecture
@testable import Reports
import XCTest

final class ReportFeatureTests: XCTestCase {

    var store: TestStoreOf<ReportFeature>!
    // assume first entry is the .spendingByTotal chart type.
    let chart = ReportChart.firstChart

    @MainActor
    func testConfirmationDialogSave() async throws {
        // reportUpdated - true triggers to save a report
        store = createTestStore(reportUpdated: true)

        // Given
        await store.send(.doneButtonTapped) {
            $0.confirmationDialog = Self.expectedConfirmationDialog
        }

        // When
        await store.send(.confirmationDialog(.presented(.saveNewReport))) {
            // Then
            $0.confirmationDialog = nil
            // complete test when save logic added.
        }
    }

    @MainActor
    func testFetchedTransactionsDisplaySelectedGraph() async throws {
        store = createTestStore()

        // only interested in state changes made in this feature and ignore
        // the  transactions values set in the state object of ChartGraph.spendingByTotal
        store.exhaustivity = .off

        // When a input fields view returns fetched transactions.
        // The delegate updates the Reports view accordingly with the selected report type.
        XCTAssertNil(store.state.chartGraph)
        await store.send(\.inputFields.delegate.fetchedTransactions, .mocksTwo) {
            $0.reportUpdated = true
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
        store = createTestStore()

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

    @MainActor
    private func createTestStore(reportUpdated: Bool = false) -> TestStoreOf<ReportFeature> {
        TestStore(
            initialState: try! .init(
                sourceData: .new(.init(chart: chart)),
                reportUpdated: reportUpdated
            )
        ) {
            ReportFeature()
        }
    }
}

// MARK: - Expected Data Values

// Extract to make tests call sites code more readable with verbose data structures given
// descriptive names below
private extension ReportFeatureTests {

    static var expectedConfirmationDialog: ConfirmationDialogState<ReportFeature.Action.ConfirmationDialog> {
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
}

private extension Array where Element == TransactionEntry {

    static let mocksTwo: Self = {
        IdentifiedArrayOf<TransactionEntry>.mocksTwo.elements
    }()
}
