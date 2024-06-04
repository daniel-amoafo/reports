// Created by Daniel Amoafo on 4/5/2024.

import BudgetSystemService
import ComposableArchitecture
@testable import Reports
import XCTest

 final class ReportFeatureTests: XCTestCase {

    var store: TestStoreOf<ReportFeature>!

     @MainActor
     override func setUp() async throws {
         // pre load the workspace with account info,
         // Account infomation is access in mutliple areas, hot loading in workspace
         // instead of fetch db frequently.
         @Shared(.wsValues) var workspaceValues
         workspaceValues.accountsOnBudgetNames = Factory.accountIdAndName
     }

     override func tearDown() async throws {
         try? store.dependencies.database.swiftData.delete(model: SavedReport.self)
     }

    @MainActor
    func testSavingNewReport() async throws {
        store = Factory.createTestStore(sourceData: Factory.newSourceData)

        XCTAssertTrue(store.state.inputFields.isRunReportDisabled)

        // select accounts for report
        store.state.inputFields.workspaceValues
            .updateSelectedAccountIds(ids: "account3ID,account1ID")
        XCTAssertFalse(store.state.inputFields.isRunReportDisabled)

        // dont check the chartGraph value
        store.exhaustivity = .off
        // initiate report run from inputFields delegate,
        await store.send(\.inputFields.delegate.reportReadyToRun)
        await store.receive(\.chartDisplayed) {
            $0.scrollToId = "GraphChartContainer"
        }

        store.exhaustivity = .on
        await store.send(.doneButtonTapped) {
            // prompts save
            $0.confirmationDialog = Factory.expectedNewConfirmationDialog
        }

        await store.send(.confirmationDialog(.presented(.saveNewReport))) {
            $0.confirmationDialog = nil
            $0.showSavedReportNameAlert = true
            $0.savedReportName = "2024 Jan - Mar, First Account, Third Account"
        }

        let savedReportQuery = store.dependencies.savedReportQuery
        let savedReportCount = try savedReportQuery.fetchCount(.init())
        XCTAssertEqual(savedReportCount, 0)

        await store.send(.savedReportName(shouldSave: true)) {
            $0.showSavedReportNameAlert = false
        }

        // Verify new report successfully persisted
        let updatedSavedReportCount = try savedReportQuery.fetchCount(.init())
        XCTAssertEqual(updatedSavedReportCount, 1)
    }

    @MainActor
    func testUpdatingSavedReport() async throws {
        let savedReport = Factory.createSavedReport()
        store = Factory.createTestStore(sourceData: .existing(savedReport))

        // verify saved report was persisted
        let savedReportQuery = store.dependencies.savedReportQuery
        let savedReports = try savedReportQuery.fetchAll()
        XCTAssertEqual(savedReports.count, 1)
        XCTAssertEqual(try XCTUnwrap(savedReports.first?.id), savedReport.id)

        // verify all input fields are valid and report can run
        XCTAssertFalse(store.state.inputFields.isRunReportDisabled)

        await store.send(.onAppear) {
            $0.inputFields
                .workspaceValues
                .selectedAccountIdsSet = Set(["account2ID", "account3ID"])
        }
        await store.receive(\.reportReadyToRun) {
            $0.chartGraph = .spendingByTotal(
                .init(
                    title: "Spending Total",
                    budgetId: savedReport.budgetId,
                    startDate: Date.local.date(from: savedReport.fromDate)!,
                    finishDate: Date.local.date(from: savedReport.toDate)!,
                    accountIds: self.store.state.inputFields.selectedAccountIds
                )
            )
        }
        await store.receive(\.chartDisplayed) {
            $0.scrollToId = "GraphChartContainer"
        }

        // Make a change to input field values. This indicates saved report needs updating
        let toDate = Date.now.advanced(by: 3600)
        await store.send(\.inputFields.updateToDateTapped, toDate) {
            $0.inputFields.toDate = toDate
        }

        await store.send(.doneButtonTapped) {
            $0.confirmationDialog = Factory.expectedUpdateExistingConfirmationDialog
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

}

/// Extract to make tests call sites code more readable with verbose data structures given
/// descriptive names below
private enum Factory {

    typealias SourceData = ReportFeature.State.SourceData
    typealias ChartGraph = ReportFeature.ChartGraph
    typealias Action = ReportFeature.Action
    typealias Destination = ReportFeature.Destination

    static let budgetId = "budget1ID"
    static let fromDate = Date.local.date(from: "2024-01-01")!
    static let toDate = Date.local.date(from: "2024-03-31")!

    static var mocksTwo: [TransactionEntry] {
        IdentifiedArrayOf<TransactionEntry>.mocksTwo.elements
    }

    static var newSourceData: SourceData {
        .new(
            .init(
                chart: .firstChart,
                budgetId: budgetId,
                fromDate: fromDate,
                toDate: toDate
            )
        )
    }

    static let accountIdAndName = [
        "account1ID": "First Account",
        "account2ID": "Second Account",
        "account3ID": "Third Account",
    ]

    static func createTestStore(
        sourceData: SourceData,
        chartGraph: ChartGraph.State? = nil,
        confirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog>? = nil,
        destination: Destination.State? = nil,
        scrollToId: String? = nil,
        showSavedReportNameAlert: Bool = false
    ) -> TestStoreOf<ReportFeature> {
        TestStore(
            initialState: try! ReportFeature.State(
                sourceData: sourceData,
                chartGraph: chartGraph,
                confirmationDialog: confirmationDialog,
                destination: destination,
                scrollToId: scrollToId,
                showSavedReportNameAlert: showSavedReportNameAlert
            )
        ) {
            ReportFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()

            // persist a savedReport into SwiftData if one is provided
            if case let .existing(savedReport) = sourceData {
                try! $0.savedReportQuery.add(savedReport)
            }
        }
    }

    static func createSavedReport() -> SavedReport {
        .init(
            name: "My First Report",
            fromDate: "2024-01-01",
            toDate: "2024-01-30",
            chartId: ReportChart.firstChart.id,
            budgetId: budgetId,
            selectedAccountIds: "account2ID,account3ID",
            lastModified: Date.local.date(from: "2024-02-02")!
        )
    }

    static var expectedNewConfirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog> {
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

    static var expectedUpdateExistingConfirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog> {
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
