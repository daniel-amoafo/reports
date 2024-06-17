// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import SwiftData

@Reducer
struct HomeFeature: Sendable {

    static let maxDisplayedSavedReports = 3
    @ObservableState
    struct State: Equatable, Sendable {
        var selectedBudgetId: String?
        var budgetList: IdentifiedArrayOf<BudgetSummary>?
        var charts: [ReportChart] = []
        var displaySavedReports: [DisplaySavedReport] = []
        var totalSavedReportsCount: Int = 0
        var showSelectBudget = false

        var selectedBudgetName: String? {
            guard let selectedBudgetId else { return nil }
            return budgetList?[id: selectedBudgetId]?.name
        }

        func isReportBottomRow(_ displayedSavedReport: DisplaySavedReport) -> Bool {
            // If savedReports.count is equal to max then a final row with a button will be displayed.
            // It doesn't matter if this is the last savedReport entry.
            guard displaySavedReports.count != maxDisplayedSavedReports else { return false }

            if let lastReport = displaySavedReports.last, lastReport == displayedSavedReport {
                return true
            }
            return false
        }
    }

    enum Action: Sendable {
        case didTapSelectBudgetButton
        case didUpdateSelectedBudgetId(String?)
        case didSelectChart(ReportChart)
        case didUpdateSavedReports
        case didSelectSavedReport(UUID)
        case delegate(Delegate)
        case showSelectBudgetTapped(Bool)
        case viewAllButtonTapped
        case onAppear
        case task
    }

    @CasePathable
    enum Delegate {
        case navigate(to: MainTab.Tab)
        case presentReport(ReportFeature.State.SourceData)
    }

    // MARK: Dependencies

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.configProvider) var configProvider
    @Dependency(\.savedReportQuery) var savedReportQuery
    @Dependency(\.continuousClock) var clock
    @Dependency(\.modelContextNotifications) var modelContextNotifications

    static let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .didTapSelectBudgetButton:
                state.showSelectBudget = true
                return .none

            case let .showSelectBudgetTapped(isPresented):
                state.showSelectBudget = isPresented
                return .none

            case let .didUpdateSelectedBudgetId(selectedBudgetId):
                guard state.selectedBudgetId != selectedBudgetId else { return .none }
                state.selectedBudgetId = selectedBudgetId
                Self.logger.debug("selectedBudgetId updated to: \(selectedBudgetId ?? "[nil]")")
                return .run { _ in
                    guard let selectedBudgetId else { return }
                    updateBudgetClientSelectedBudgetId(selectedBudgetId)
                }

            case let .didSelectChart(chart):
                guard let budgetId = state.selectedBudgetId else {
                    return .none
                }
                let sourceData = ReportFeature.State.SourceData.new(.init(chart: chart, budgetId: budgetId))
                return .send(.delegate(.presentReport(sourceData)))

            case .didUpdateSavedReports:
                let (displayedSavedReports, total) = fetchDisplayedSavedReports()
                state.displaySavedReports = displayedSavedReports
                state.totalSavedReportsCount = total
                return .none

            case let .didSelectSavedReport(id):
                let sourceData = ReportFeature.State.SourceData.existing(id)
                return .send(.delegate(.presentReport(sourceData)))

            case .viewAllButtonTapped:
                return .send(.delegate(.navigate(to: .reports)))

            case .onAppear:
                MainActor.assumeIsolated {
                    state.budgetList = budgetClient.budgetSummaries
                }
                state.selectedBudgetId = configProvider.selectedBudgetId
                state.charts = configProvider.charts
                return .run { send in
                    await send(.didUpdateSavedReports)
                }

            case .task:
                return .run { send in
                    for await _ in await modelContextNotifications.didUpdate(SavedReport.self) {
                        try? await clock.sleep(for: .seconds(0.5))
                        await send(.didUpdateSavedReports, animation: .smooth)
                    }
                }

            case .delegate:
                return .none
            }
        }
    }
}

private extension HomeFeature {

    func updateBudgetClientSelectedBudgetId(_ selectedBudgetId: String) {
        configProvider.selectedBudgetId = selectedBudgetId
    }

    func fetchDisplayedSavedReports() -> ([DisplaySavedReport], Int) {
        do {
            var descriptor = FetchDescriptor<SavedReport>(
                sortBy: [
                    .init(\.lastModifield, order: .reverse)
                ]
            )
            descriptor.fetchLimit = Self.maxDisplayedSavedReports
            let displayedSavedReports = try savedReportQuery.fetch(descriptor).map(DisplaySavedReport.init)
            let total = try savedReportQuery.fetchCount(FetchDescriptor<SavedReport>())
            return (displayedSavedReports, total)
        } catch {
            Self.logger.error("\(error.toString())")
            return ([], 0)
        }
    }

}
