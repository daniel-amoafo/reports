// Created by Daniel Amoafo on 8/3/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftData
import SwiftUI

@Reducer
struct HomeFeature {

    @ObservableState
    struct State: Equatable {
        var selectedBudgetId: String?
        var budgetList: IdentifiedArrayOf<BudgetSummary>?
        var charts: [ReportChart] = []
        var savedReports: [SavedReport] = []
        var savedReportsCount: Int = 0
        var showSelectBudget = false

        var selectedBudgetName: String? {
            guard let selectedBudgetId else { return nil }
            return budgetList?[id: selectedBudgetId]?.name
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

    let logger = LogFactory.create(category: .home)

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
                let (savedReports, total) = fetchSavedReports()
                state.savedReports = savedReports
                state.savedReportsCount = total
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
                    for await _ in await savedReportQuery.didUpdateNotification() {
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

    var isSelectedBudgetIdSet: Bool {
        budgetClient.selectedBudgetId != nil
    }

    func updateBudgetClientSelectedBudgetId(_ selectedBudgetId: String) {
        do {
            try budgetClient.updateSelectedBudgetId(selectedBudgetId)
            configProvider.selectedBudgetId = selectedBudgetId

        } catch {
            logger.error("Error attempting to update selectedBudgetId: \(error.localizedDescription)")
        }
    }

    func fetchSavedReports() -> ([SavedReport], Int) {
        do {
            var descriptor = FetchDescriptor<SavedReport>(
                sortBy: [
                    .init(\.lastModifield, order: .reverse)
                ]
            )
            descriptor.fetchLimit = 4
            let savedReports = try savedReportQuery.fetch(descriptor)
            let total = try savedReportQuery.fetchCount(FetchDescriptor<SavedReport>())
            return (savedReports, total)
        } catch {
            logger.error("\(error.localizedDescription)")
            return ([], 0)
        }
    }

}

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @State var selectedString: String?
    private let logger = LogFactory.create(category: .home)

    @State private var viewAllFrame: CGRect = .zero
    private let maxDisplayedSavedReports = 3

    var body: some View {
        ZStack {
            Color.Surface.primary
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .Spacing.pt24) {
                        // New Report Section
                        newReportSectionView

                        // Select Budget Picker Section
                        budgetPickerSectionView

                        // Saved Reports Section
                        savedReportsSectionView
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(Text(Strings.title))
        .onAppear {
            store.send(.onAppear)
        }
        .task {
            await store.send(.task).finish()
        }
    }
}

private extension HomeView {

    var newReportSectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .Spacing.pt12) {
                ForEach(store.charts) { chart in
                    ChartButtonView(title: chart.name, image: chart.type.image) {
                        store.send(.didSelectChart(chart))
                    }
                }
            }
            .padding(.vertical, .Spacing.pt16)
        }
        .contentMargins(.leading, .Spacing.pt16)
        .padding(.top, .Spacing.pt24)
    }

    var budgetPickerSectionView: some View {
        VStack {
            Button(action: {
                store.send(.didTapSelectBudgetButton)
            }, label: {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(Color.Icon.secondary)
                    if let budgetName = store.selectedBudgetName {
                        Text(budgetName)
                    } else {
                        Text(Strings.selectBudgetTitle)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            })
            .buttonStyle(.listRowSingle)
            .backgroundShadow()
            .padding(.horizontal)
            .popover(isPresented: $store.showSelectBudget.sending(\.showSelectBudgetTapped)) {
                if let budgetList = store.budgetList {
                    SelectListView<BudgetSummary>(
                        items: budgetList,
                        selectedItem: $store.selectedBudgetId.sending(\.didUpdateSelectedBudgetId)
                    )
                }
            }
        }
    }

    var savedReportsSectionView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(Strings.savedReportsButtonTitle)
                    .typography(.title3Emphasized)
                    .foregroundStyle(Color.Text.secondary)
                Spacer()
            }
            .listRowTop(showHorizontalRule: false)

            if store.savedReports.isEmpty {
                Text("[No Reports]") // fix UI
            } else {
                savedReportsListView
            }
        }
        .backgroundShadow()
        .padding(.horizontal, .Spacing.pt16)
    }

    var savedReportsListView: some View {
        VStack(spacing: 0) {
            ForEach(store.savedReports.prefix(maxDisplayedSavedReports)) { savedReport in
                if let reportType = ReportChart.defaultCharts[id: savedReport.chartId] {
                    Button(action: {
                        store.send(.didSelectSavedReport(savedReport))
                    }, label: {
                        HStack(spacing: .Spacing.pt12) {
                            reportType.type.image
                                .resizable()
                                .frame(width: 42, height: 42)
                            VStack(alignment: .leading) {
                                Text(savedReport.name)
                                    .typography(.headlineEmphasized)
                                    .foregroundStyle(Color.Text.primary)
                                Text(reportType.name)
                                    .typography(.bodyEmphasized)
                                    .foregroundStyle(Color.Text.secondary)
                            }
                            Spacer()
                        }
                    })
                    .buttonStyle(.listRow)
                }
            }

            // Footer row with View All button if needed
            VStack {
                if store.savedReports.count > maxDisplayedSavedReports {
                    Button(String(format: Strings.viewAllButtonTitle, arguments: [store.savedReportsCount])) {
                        store.send(.viewAllButtonTapped)
                    }
                    .buttonStyle(.kleonPrimary)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.7
                    }
                } else {
                    Text("")
                }
            }
            .listRowBottom()
        }
    }
}

// MARK: -

private enum Strings {
    static let title = String(localized: "Budget Reports", comment: "The home screen main title")
    static let savedReportsButtonTitle = String(localized: "Saved Reports", comment: "List Title for Saved Reports")
    static let viewAllButtonTitle = String(
        localized: "View All (%d)",
        comment: "Move to the Saved Report screen. Displays count of reports saved."
    )
    static let selectBudgetTitle = String(
        localized: "Select a budget",
        comment: "Placeholder text if no budget has been set."
    )
}

// MARK: - Previews

#Preview {
    NavigationStack {
        HomeView(
            store: Store(initialState: HomeFeature.State()) {
                HomeFeature()
            }
        )
    }
}
