// Created by Daniel Amoafo on 30/5/2024.

import BudgetSystemService
import ComposableArchitecture
import Foundation
import SwiftData

@Reducer
struct HomeFeature {

    static let maxDisplayedSavedReports = 3
    @ObservableState
    struct State: Equatable {
        var selectedBudgetId: String?
        var budgetList: IdentifiedArrayOf<BudgetSummary>?
        var charts: [ReportChart] = []
        var displayedSavedReports: [SavedReport] = []
        var totalSavedReportsCount: Int = 0
        var showSelectBudget = false

        var selectedBudgetName: String? {
            guard let selectedBudgetId else { return nil }
            return budgetList?[id: selectedBudgetId]?.name
        }

        func isReportBottomRow(_ savedReport: SavedReport) -> Bool {
            // if savedReports.count is equal to max then a final row with a button is displayed.
            // Dont matter if this is the last savedReport entry.
            guard displayedSavedReports.count != maxDisplayedSavedReports else { return false }
            if let lastReport = displayedSavedReports.last, lastReport.id == savedReport.id {
                return true
            }
            return false
        }
    }

    enum Action {
        case didTapSelectBudgetButton
        case didUpdateSelectedBudgetId(String?)
        case didSelectChart(ReportChart)
        case didUpdateSavedReports
        case didSelectSavedReport(SavedReport)
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

    let logger = LogFactory.create(Self.self)

    var body: some ReducerOf<Self> {
        Reduce { state, action in
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
                logger.debug("selectedBudgetId updated to: \(selectedBudgetId ?? "[nil]")")
                return .run { _ in
                    guard let selectedBudgetId else { return }
                    updateBudgetClientSelectedBudgetId(selectedBudgetId)
                }

            case let .didSelectChart(chart):
                let sourceData = ReportFeature.State.SourceData.new(.init(chart: chart))
                return .send(.delegate(.presentReport(sourceData)))

            case .didUpdateSavedReports:
                let (savedReports, total) = fetchDisplayedSavedReports()
                state.displayedSavedReports = savedReports
                state.totalSavedReportsCount = total
                return .none

            case let .didSelectSavedReport(savedReport):
                let sourceData = ReportFeature.State.SourceData.existing(savedReport)
                return .send(.delegate(.presentReport(sourceData)))

            case .viewAllButtonTapped:
                return .send(.delegate(.navigate(to: .reports)))

            case .onAppear:
                state.budgetList = budgetClient.budgetSummaries
                state.selectedBudgetId = budgetClient.selectedBudgetId
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
        do {
            try budgetClient.updateSelectedBudgetId(selectedBudgetId)
            configProvider.selectedBudgetId = selectedBudgetId

        } catch {
            logger.error("Error attempting to update selectedBudgetId: \(error.toString())")
        }
    }

    func fetchDisplayedSavedReports() -> ([SavedReport], Int) {
        do {
            var descriptor = FetchDescriptor<SavedReport>(
                sortBy: [
                    .init(\.lastModifield, order: .reverse)
                ]
            )
            descriptor.fetchLimit = Self.maxDisplayedSavedReports
            let savedReports = try savedReportQuery.fetch(descriptor)
            let total = try savedReportQuery.fetchCount(FetchDescriptor<SavedReport>())
            return (savedReports, total)
        } catch {
            logger.error("\(error.toString())")
            return ([], 0)
        }
    }

}
