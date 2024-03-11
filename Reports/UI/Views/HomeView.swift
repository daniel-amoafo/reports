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

        var selectedBudgetName: String? {
            guard let selectedBudgetId else { return nil }
            return budgetList?[id: selectedBudgetId]?.name
        }
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case didTapSelectBudgetButton
        case didUpdateSelectedBudgetId(String?)
        case onAppear
    }

    @Reducer(state: .equatable)
    enum Destination {
        case popoverSelectBudget(Home)
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
            case .onAppear:
                state.budgetList = budgetClient.budgetSummaries
                state.selectedBudgetId = budgetClient.selectedBudgetId
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
            configProvider.storedSelectedBudgetId = selectedBudgetId

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

    var body: some View {
        ZStack {
            Color(R.color.colors.surface.primary)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Text(Strings.title)
                    .typography(.title1Emphasized)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .Spacing.large) {
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
        .onAppear {
            store.send(.onAppear)
        }

    }
}

private extension HomeView {

    var newReportSectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .Spacing.small) {
                ForEach(0..<10) {
                    Text("Item \($0)")
                        .typography(.title2Emphasized)
                        .foregroundStyle(.white)
                        .frame(width: 140, height: 166)
                        .background(.red)
                }
            }
        }
        .contentMargins(.leading, .Spacing.medium)
        .padding(.top, .Spacing.large)
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
            .padding(.horizontal, .Spacing.medium)
            .popover(item: $store.scope(
                state: \.destination?.popoverSelectBudget,
                action: \.destination.popoverSelectBudget
            )) { _ in
                if let budgetList = store.budgetList {
                    // this binding is not ideal.
                    // should belong in the state object rather than inline defined here :/
                    let selectedBudgetId = Binding<String?> {
                        store.selectedBudgetId
                    } set: { newValue in
                        store.send(.didUpdateSelectedBudgetId(newValue))
                        logger.debug("selectedBudgetId set by popover - \(newValue ?? "[nil]")")
                    }
                    SelectListView<BudgetSummary>(items: budgetList, selectedItem: selectedBudgetId)
                }
            }
        }
    }

    var savedReportsSectionView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Saved Reports")
                    .typography(.title3Emphasized)
                    .foregroundColor(Color(R.color.colors.text.secondary))
                Spacer()
            }
            .listRowTop(showHorizontalRule: false)

            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                HStack(spacing: .Spacing.small) {
                    Image(R.image.pieChart)
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
            .buttonStyle(.listRowMiddle)

            GeometryReader { geometry in
                HStack {
                    Button("View All") {

                    }
                    .buttonStyle(.kleonPrimary)
                }
                .frame(width: geometry.size.width * 0.6)
                .listRowBottom()
            }
        }
        .padding(.horizontal, .Spacing.medium)
    }
}

#Preview {
    HomeView(
        store: Store(initialState: Home.State()) {
            Home()
        }
    )
}
