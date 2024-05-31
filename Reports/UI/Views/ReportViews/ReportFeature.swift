// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation

@Reducer
struct ReportFeature {

    @ObservableState
    struct State: Equatable {

        enum SourceData {
            case new(ReportInputFeature.State)
            case existing(SavedReport)
        }

        var inputFields: ReportInputFeature.State
        var savedReport: SavedReport?
        @Presents var chartGraph: ChartGraph.State?
        @Presents var confirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog>?
        @Presents var destination: Destination.State?
        var scrollToId: String?
        var showSavedReportNameAlert = false
        var savedReportName: String = ""

        var reportTitle: String {
            guard let savedReportTitle = savedReport?.name else {
                return Strings.newReportTitle
            }
            return savedReportTitle
        }
        var chartContainerId: String { "GraphChartContainer" }

        var saveReportSuggestedName: String {
            let fromYear = inputFields.fromDate.formatted(.dateTime.year())
            let fromMonth = inputFields.fromDate.formatted(.dateTime.month())
            let toYear = inputFields.toDate.formatted(.dateTime.year())
            let toMonth = inputFields.toDate.formatted(.dateTime.month())
            let accountName = "\(inputFields.selectedAccountName ?? Account.allAccounts.name)"

            if fromYear == toYear {
                return "\(fromYear) \(fromMonth) - \(toMonth), \(accountName)"
            }
            return "\(fromMonth) \(fromYear) - \(toMonth) \(toYear), \(accountName)"
        }

        var budgetId: String {
            // todo add budgetId into SavedReport an retrieve from here if running a savedReport
            @Dependency(\.configProvider) var configProvider
            return configProvider.selectedBudgetId ?? ""
        }

        var hasUnsavedChanges: Bool {
            if let savedReport {
                // compare if saved report input fields are equal to current input field values.
                // if not, there are unsaved changes
                return !inputFields.isEqual(to: savedReport)
            }

            if chartGraph != nil {
                // new report with chart being displayed
                return true
            }

            return false
        }

        init(
            sourceData: SourceData,
            chartGraph: ChartGraph.State? = nil,
            confirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog>? = nil,
            destination: Destination.State? = nil,
            scrollToId: String? = nil,
            showSavedReportNameAlert: Bool = false
        ) throws {
            // Ensure Report is correctly configured with inputField values.
            // For a SavedReport, validate values being populated are still valid.
            let (inputFields, savedReport) = try ReportFeatureSourceLoader.load(sourceData)
            self.inputFields = inputFields
            self.savedReport = savedReport
            self.chartGraph = chartGraph
            self.confirmationDialog = confirmationDialog
            self.destination = destination
            self.scrollToId = scrollToId
            self.showSavedReportNameAlert = showSavedReportNameAlert
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case inputFields(ReportInputFeature.Action)
        case chartGraph(PresentationAction<ChartGraph.Action>)
        case confirmationDialog(PresentationAction<ConfirmationDialog>)
        case destination(PresentationAction<Destination.Action>)
        case showSavedReportNameAlert(isPresented: Bool)
        case savedReportName(shouldSave: Bool)
        case reportReadyToRun
        case chartDisplayed
        case doneButtonTapped
        case onAppear

        enum ConfirmationDialog {
            case saveNewReport
            case updateExistingReport
            case discard
        }

    }

    @Reducer(state: .equatable)
    enum ChartGraph {
        case spendingByTotal(SpendingTotalChartFeature)
    }

    @Reducer(state: .equatable)
    enum Destination {
      case transactionHistory(TransactionHistoryFeature)
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.isPresented) var isPresented
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.savedReportQuery) var savedReportQuery
    @Dependency(\.continuousClock) var clock

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.inputFields, action: \.inputFields) {
            ReportInputFeature()
        }
        Reduce { state, action in
            switch action {
            case let .confirmationDialog(.presented(action)):
                switch action {
                case .saveNewReport:
                    state.savedReportName = state.saveReportSuggestedName
                    state.showSavedReportNameAlert = true
                    return .none
                case .updateExistingReport:
                    state.savedReportName = state.savedReport?.name ?? ""
                    state.showSavedReportNameAlert = true
                    return .none
                case .discard:
                    break
                }
                return .run { _ in
                    if isPresented {
                        await dismiss()
                    }
                }

            case let .savedReportName(shouldSave):
                state.showSavedReportNameAlert = false
                guard shouldSave else { return .none }
                saveReport(
                    name: state.savedReportName,
                    inputFields: state.inputFields,
                    existing: state.savedReport
                )
                return .run { _ in
                    if isPresented {
                        await dismiss()
                    }
                }

            case .reportReadyToRun, .inputFields(.delegate(.reportReadyToRun)):
                let chartTitle = state.inputFields.chart.name
                switch state.inputFields.chart.type {
                case .spendingByTotal:
                    state.chartGraph = .spendingByTotal(
                        .init(
                            title: chartTitle,
                            budgetId: state.budgetId,
                            startDate: state.inputFields.fromDate,
                            finishDate: state.inputFields.toDate,
                            accountId: state.inputFields.santizedSelectedAccountId
                        )
                    )
                case .spendingByTrend:
                    break
                case .incomeExpensesTable:
                    break
                case .line:
                    break
                }
                guard state.chartGraph != nil else { return .none }
                state.scrollToId = nil
                return .run { send in
                    try await self.clock.sleep(for: .seconds(0.5))
                    await send(.chartDisplayed, animation: .easeInOut)
                }

            case let .chartGraph(.presented(.spendingByTotal(.delegate(.categoryTapped(transactions))))):
                let array = transactions.elements
                state.destination = .transactionHistory(.init(transactions: array, title: array.first?.categoryName))
                return .none

            case .chartDisplayed:
                state.scrollToId = state.chartContainerId
                return .none

            case .doneButtonTapped:
                if state.hasUnsavedChanges {
                    state.confirmationDialog = makeConfirmDialog(isNew: state.savedReport == nil)
                    return .none
                } else {
                    return .run { _ in
                        if isPresented {
                            await dismiss()
                        }
                    }
                }

            case .onAppear:
                // Run report if we have a Saved Report
                if state.savedReport != nil {
                    return .send(.reportReadyToRun)
                }
                return .none

            case .inputFields, .chartGraph, .binding,
                .destination, .confirmationDialog, .showSavedReportNameAlert:
                return .none
            }
        }
        .ifLet(\.$chartGraph, action: \.chartGraph)
        .ifLet(\.$confirmationDialog, action: \.confirmationDialog)
        .ifLet(\.$destination, action: \.destination)
    }
}

private extension ReportFeature {

    func makeConfirmDialog(isNew: Bool) -> ConfirmationDialogState<Action.ConfirmationDialog> {
        .init {
            TextState("")
        } actions: {
            ButtonState(action: isNew ? .saveNewReport : .updateExistingReport) {
                TextState(AppStrings.saveButtonTitle)
            }
            ButtonState(role: .destructive, action: .discard) {
                TextState(Strings.confirmDiscard)
            }
            ButtonState(role: .cancel) {
                TextState(AppStrings.cancelButtonTitle)
            }
        } message: {
            TextState(isNew ? Strings.confirmSaveNewReport : Strings.confirmUpdateSavedReport)
        }
    }

    func saveReport(name: String, inputFields: ReportInputFeature.State, existing: SavedReport?) {
        do {
            let selectedAccountId = inputFields.selectedAccountId == Account.allAccountsId ?
            nil : inputFields.selectedAccountId

            let savedReport: SavedReport
            if let existingReport = existing {
                existingReport.name = name
                existingReport.fromDate = inputFields.fromDateFormatted
                existingReport.toDate = inputFields.toDateFormatted
                existingReport.selectedAccountId = selectedAccountId
                existingReport.lastModifield = .now
                savedReport = existingReport
            } else {
                savedReport = SavedReport(
                    name: name,
                    fromDate: inputFields.fromDateFormatted,
                    toDate: inputFields.toDateFormatted,
                    chartId: inputFields.chart.id,
                    selectedAccountId: selectedAccountId,
                    lastModified: .now
                )
            }
            try savedReportQuery.add(savedReport)

        } catch {
            logger.error("\(error.toString())")
        }
    }

}

// MARK: -

private enum Strings {
    static let newReportTitle = String(
        localized: "New Report",
        comment: "the title when a new report is being created"
    )
    static let confirmDiscard = String(
        localized: "Discard",
        comment: "Confirmation action to not save changes & exit"
    )
    static let confirmSaveNewReport = String(
        localized: "Save New Report?", comment: "Confirmation message when saving a new report."
    )
    static let confirmUpdateSavedReport = String(
        localized: "Update Saved Report?", comment: "Confirmation message when updating an existing saved report."
    )
}
