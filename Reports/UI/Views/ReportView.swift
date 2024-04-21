// Created by Daniel Amoafo on 15/4/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

@Reducer
struct ReportFeature {

    @ObservableState
    struct State: Equatable {
        let chart: Chart
        var showChartMoreInfo = false
        var fromDate: Date = .now
        var toDate: Date = .aWeekFrom(.now)
        var accounts: IdentifiedArrayOf<Account>?
        var selectedAccountId: String?
        var reportLoading = false
        var showAccountList = false

        var chartMoreInfoArrowDirection: String {
            showChartMoreInfo ? "down" : "right"
        }

        var selectedAccountName: String? {
            guard let selectedAccountId else { return nil }
            return accounts?[id: selectedAccountId]?.name
        }

        var isAccountSelected: Bool {
            selectedAccountId != nil
        }

        var isRunReportDisabled: Bool {
            !isAccountSelected
        }
    }

    enum Action {
        case chartMoreInfoTapped
        case updateFromDateTapped(Date)
        case updateToDateTapped(Date)
        case selectAccountRowTapped(Bool)
        case didSelectAccountId(String?)
        case runReportTapped
        case reportReponse(IdentifiedArrayOf<BudgetSystemService.Transaction>)
        case onAppear
    }

    @Dependency(\.budgetClient) var budgetClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .chartMoreInfoTapped:
                state.showChartMoreInfo = !state.showChartMoreInfo
                return .none
            case let .updateFromDateTapped(fromDate):
                state.fromDate = fromDate
                return .none
            case let .updateToDateTapped(toDate):
                state.toDate = toDate
                return .none
            case .runReportTapped:
                guard !state.reportLoading else { return .none }
                state.reportLoading = true
                return .run { [state] send in
                    await fetchReport(state: state, send: send)
                }
            case let .reportReponse(transaction):
                // call report graph
                state.reportLoading = false
                print(transaction.count)
                return .none
            case .onAppear:
                if state.accounts == nil {
                    state.accounts = budgetClient.accounts
                }
                return .none
            case let .selectAccountRowTapped(isActive):
                state.showAccountList = isActive
                return .none
            case let .didSelectAccountId(accountId):
                state.selectedAccountId = accountId
                return .none
            }
        }
    }
}

private extension ReportFeature {

    func fetchReport(state: ReportFeature.State, send: Send<ReportFeature.Action>) async {

        do {
            let transactions = try await budgetClient.fetchTransactionsAll(startDate: state.fromDate)
            await send(.reportReponse(transactions))
        } catch {

        }
    }
}

private enum Strings {
    static let newReportTitle = String(localized: "New Report", comment: "the title when a new report is being created")
    static let chartTitle = String(localized: "Chart", comment: "the title name for the chart section")
    static let moreInfoTitle = String(
        localized: "More Info",
        comment: "the title to as ection that displays more descriptive text about the chart"
    )
    static let fromDateTitle = String(localized: "From", comment: "the start date field title")
    static let toDateTitle = String(localized: "To", comment: "the end date field title")
    static let runReportTitle = String(localized: "Run", comment: "Generates a new report")
    static let selectAccountTitle = String(
        localized: "Select Account",
        comment: "title for selecting the bank account to run report from"
    )
    static let selectAccountPlaceholder = String(
        localized: "Please select an account for the report",
        comment: "the account for which the transactions the report will be based on"
    )
}

struct ReportView: View {

    @Bindable var store: StoreOf<ReportFeature>

    @ScaledMetric(relativeTo: .body) private var chartMoreInfoArrowSize: CGFloat = 5.0
    @ScaledMetric(relativeTo: .body) private var chartImageWidth: CGFloat = 46.0
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 14.0

    var body: some View {
        ZStack {
            Color(R.color.surface.primary)
                .ignoresSafeArea()
            VStack(spacing: .Spacing.xsmall) {
                Text(Strings.newReportTitle)
                    .typography(.title2Emphasized)
                ScrollView {
                    VStack(spacing: 0) {
                        chartAndInputSection

                        dateInputSection

                        accountSection

                        runReportSection
                    }
                    .backgroundShadow()
                }
                .contentMargins(.all, 8.0, for: .scrollContent)
            }
        }
        .task {
            store.send(.onAppear)
        }
    }

    var chartAndInputSection: some View {
        VStack {
            VStack(spacing: 0) {
                VStack(spacing: .Spacing.small) {
                    HStack(spacing: 0) {
                        // Chart Title and Name
                        VStack(alignment: .leading, spacing: 0) {
                            Text(Strings.chartTitle)
                                .typography(.title2Emphasized)
                                .foregroundColor(Color(R.color.text.secondary))
                            Text(store.chart.name)
                                .typography(.headlineEmphasized)
                        }
                        Spacer()
                        Spacer()
                        Spacer()
                        // Chart Image
                        store.chart.type.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: chartImageWidth)
                        Spacer()
                    }
                    // More Info
                    VStack {
                        HStack(spacing: .Spacing.xxsmall) {
                            Button(
                                action: {
                                    store.send(.chartMoreInfoTapped, animation: .default)
                                },
                                label: {
                                    Image(systemName: "arrowtriangle.\(store.chartMoreInfoArrowDirection).fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: chartMoreInfoArrowSize)
                                    Text(Strings.moreInfoTitle)
                                        .typography(.bodyEmphasized)
                                }
                            )
                            .buttonStyle(.plain)
                            .foregroundColor(Color(R.color.text.secondary))
                            Spacer()
                        }
                        // Chart description text when expanded
                        if store.showChartMoreInfo {
                            HStack(spacing: 0) {
                                Text(store.chart.description)
                                    .typography(.body)
                                    .foregroundColor(Color(R.color.text.secondary))
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16.0)
                                    .fill(Color(R.color.surface.tertiary))
                            )
                        }
                    }
                }
                .padding(.Spacing.small)
            }
            .background(
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(Color.clear)
                    .stroke(Color(R.color.border.secondary), lineWidth: 1.0)
            )
        }
        .listRowTop()
    }

    var dateInputSection: some View {
        HStack(alignment: .iconAndTitleAlignment, spacing: .Spacing.xsmall) {
            Image(systemName: "calendar")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconWidth)
                .foregroundColor(Color(R.color.icon.secondary))
                .alignmentGuide(.iconAndTitleAlignment, computeValue: { dimension in
                    dimension[VerticalAlignment.center]
                })

            VStack {
                DatePicker(
                    selection: $store.fromDate.sending(\.updateFromDateTapped),
                    displayedComponents: .date,
                    label: {
                        Text(Strings.fromDateTitle)
                            .typography(.bodyEmphasized)
                            .alignmentGuide(.iconAndTitleAlignment, computeValue: { dimension in
                                dimension[VerticalAlignment.center]
                            })
                    }
                )

                DatePicker(
                    selection: $store.toDate.sending(\.updateToDateTapped),
                    in: store.fromDate...,
                    displayedComponents: .date,
                    label: {
                        Text(Strings.toDateTitle)
                            .typography(.bodyEmphasized)
                    }
                )
            }
            .foregroundColor(Color(R.color.text.secondary))
        }
        .listRow()
    }

    var accountSection: some View {
        Button(
            action: {
                store.send(.selectAccountRowTapped(true))
            }, label: {
                HStack(spacing: 0) {
                    HStack(alignment: .iconAndTitleAlignment, spacing: .Spacing.xsmall) {
                        Image(systemName: "building.columns.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconWidth)
                            .foregroundColor(Color(R.color.icon.secondary))
                            .alignmentGuide(
                                .iconAndTitleAlignment,
                                computeValue: { dimension in dimension[VerticalAlignment.center] }
                            )

                        VStack(alignment: .leading, spacing: .Spacing.xsmall) {
                            Text(Strings.selectAccountTitle)
                                .typography(.bodyEmphasized)
                                .foregroundColor(Color(R.color.text.secondary))
                                .alignmentGuide(
                                    .iconAndTitleAlignment,
                                    computeValue: { dimension in dimension[VerticalAlignment.center] }
                                )

                            Text("\(store.selectedAccountName ?? Strings.selectAccountPlaceholder)")
                                .typography(store.isAccountSelected ? .body : .bodyItalic)
                                .foregroundStyle(
                                    store.isAccountSelected ?
                                    Color(R.color.text.primary) : Color(R.color.text.secondary)
                                )
                        }
                        Spacer()
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(R.color.icon.secondary))
                        .padding(.trailing, .Spacing.xsmall)
                }
            }
        )
        .buttonStyle(.listRow)
        .popover(isPresented: $store.showAccountList.sending(\.selectAccountRowTapped)) {
            if let accounts = store.accounts {
                SelectListView<Account>(
                    items: accounts,
                    selectedItem: $store.selectedAccountId.sending(\.didSelectAccountId)
                )
            }
        }
    }

    var runReportSection: some View {
        HStack {
            Spacer()
            Spacer()
            Button {
                store.send(.runReportTapped, animation: .default)
            } label: {
                if store.reportLoading {
                    ProgressView()
                        .tint(Color(R.color.button.primaryTitle))
                } else {
                    Text(Strings.runReportTitle)
                        .typography(.title3Emphasized)

                }
            }
            .buttonStyle(.kleonPrimary)
            .disabled(store.isRunReportDisabled)
            Spacer()
            Spacer()
        }
        .listRowBottom()
    }
}

private extension Date {
    static func aWeekFrom(_ date: Date) -> Date {
        .init(timeInterval: TimeInterval(60*60*24*6), since: .now)
    }
}

private extension VerticalAlignment {
    /// Used to align leading icon with the matching row title text
    enum IconAndTitleAlignment: AlignmentID {
        static func defaultValue(in dimension: ViewDimensions) -> CGFloat {
            return dimension[VerticalAlignment.center]
        }
    }
    static let iconAndTitleAlignment = VerticalAlignment(IconAndTitleAlignment.self)
}

// MARK: -

#Preview {
    NavigationStack {
        ReportView(
            store: Store(initialState: ReportFeature.State(
                chart: .mock,
                accounts: .mocks
            )) {
                ReportFeature()
            }
        )
    }
}

private extension Chart {

    static let mock: Chart = Self.makeDefaultCharts()[0]
}

extension IdentifiedArray where ID == Account.ID, Element == Account {

    static let mocks: Self = [
        .init(id: "01", name: "Everyday Account"),
        .init(id: "02", name: "Acme Account"),
        .init(id: "03", name: "Appleseed Account"),
    ]
}
