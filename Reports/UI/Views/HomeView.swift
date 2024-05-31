// Created by Daniel Amoafo on 8/3/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @State var selectedString: String?
    private let logger = LogFactory.create(Self.self)

    @State private var viewAllFrame: CGRect = .zero

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

            if store.displayedSavedReports.isEmpty {
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
            ForEach(store.displayedSavedReports) { savedReport in
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
                    .buttonStyle(store.state.isReportBottomRow(savedReport) ? .listRowBottom : .listRow)
                }
            }

            // Footer row with View All button if needed
            VStack {
                if store.totalSavedReportsCount > store.displayedSavedReports.count {
                    Button(String(format: Strings.viewAllButtonTitle, arguments: [store.totalSavedReportsCount])) {
                        store.send(.viewAllButtonTapped)
                    }
                    .buttonStyle(.kleonPrimary)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.7
                    }
                    .listRowBottom()
                }
            }
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
