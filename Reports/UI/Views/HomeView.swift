// Created by Daniel Amoafo on 8/3/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

@Reducer
struct Home {

    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var selectedBudgetId: String?
        var budgetList: IdentifiedArrayOf<BudgetSummary>?
        var charts: [ReportChart] = []

        var selectedBudgetName: String? {
            guard let selectedBudgetId else { return nil }
            return budgetList?[id: selectedBudgetId]?.name
        }
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case didTapSelectBudgetButton
        case didUpdateSelectedBudgetId(String?)
        case didSelectChart(ReportChart)
        case onAppear
    }

    @Reducer(state: .equatable)
    enum Destination {
        case popoverSelectBudget(Home)
        case popoverNewReport(ReportFeature)
    }

    @Dependency(\.budgetClient) var budgetClient
    @Dependency(\.configProvider) var configProvider

    let logger = LogFactory.create(category: .home)

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didTapSelectBudgetButton:
                // needs reviewing: the state object passed is not correct.
                // it's a copy and therefore does not update the original instance. .scope(...) func needs a store. :-/
                state.destination = .popoverSelectBudget(state)
                return .none
            case let .didUpdateSelectedBudgetId(selectedBudgetId):
                guard state.selectedBudgetId != selectedBudgetId else {
                    return .none
                }
                state.selectedBudgetId = selectedBudgetId
                logger.debug("selectedBudgetId updated to: \(selectedBudgetId ?? "[nil]")")
                return .run { _ in
                    guard let selectedBudgetId else { return }
                    updateBudgetClientSelectedBudgetId(selectedBudgetId)
                }
            case let .didSelectChart(chart):
                state.destination = .popoverNewReport(
                    ReportFeature.State(inputFields: .init(chart: chart))
                )
                return .none
            case .onAppear:
                state.budgetList = budgetClient.budgetSummaries
                state.selectedBudgetId = budgetClient.selectedBudgetId
                state.charts = configProvider.charts
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        ._printChanges()
    }
}

private extension Home {

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
}

private enum Strings {
    static let title = String(localized: "Budget Reports", comment: "The home screen main title")
}

struct HomeView: View {
    @Bindable var store: StoreOf<Home>
    @State var selectedString: String?
    private let logger = LogFactory.create(category: .home)

    @State private var viewAllFrame: CGRect = .zero

    var body: some View {
        ZStack {
            Color(.Surface.primary)
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
                    if let budgetName = store.selectedBudgetName {
                        Text(budgetName)
                    } else {
                        Text("[Select budget text]")
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            })
            .buttonStyle(.listRowSingle)
            .backgroundShadow()
            .padding(.horizontal, .Spacing.pt16)
            .popover(item: $store.scope(
                state: \.destination?.popoverSelectBudget,
                action: \.destination.popoverSelectBudget
            )) { _ in
                if let budgetList = store.budgetList {
                    SelectListView<BudgetSummary>(
                        items: budgetList,
                        selectedItem: $store.selectedBudgetId.sending(\.didUpdateSelectedBudgetId)
                    )
                }
            }
            .fullScreenCover(
                item: $store.scope(state: \.destination?.popoverNewReport, action: \.destination.popoverNewReport)
            ) { store in
                NavigationStack {
                    ReportView(store: store)
                }
            }
        }
    }

    var savedReportsSectionView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Saved Reports")
                    .typography(.title3Emphasized)
                    .foregroundStyle(Color(.Text.secondary))
                Spacer()
            }
            .listRowTop(showHorizontalRule: false)

            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                HStack(spacing: .Spacing.pt12) {
                    Image(.chartPie)
                        .resizable()
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading) {
                        Text("Spending Trends")
                            .typography(.headlineEmphasized)
                        Text("Aug 23 - Dec 23, Main Budget")
                            .typography(.bodyEmphasized)
                    }
                    Spacer()
                }
            })
            .buttonStyle(.listRow)

            VStack {
                Button("View All") {

                }
                .buttonStyle(.kleonPrimary)
                .containerRelativeFrame(.horizontal) { length, _ in
                    length * 0.7
                }
            }
            .listRowBottom()
        }
        .backgroundShadow()
        .padding(.horizontal, .Spacing.pt16)
    }
}

#Preview {
    NavigationStack {
        HomeView(
            store: Store(initialState: Home.State()) {
                Home()
            }
        )
    }
}
