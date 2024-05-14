// Created by Daniel Amoafo on 15/4/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

@Reducer
struct ReportInputFeature {

    @ObservableState
    struct State: Equatable {
        let chart: ReportChart
        var showChartMoreInfo = false
        var fromDate: Date = .now.advanceMonths(by: -1, strategy: .firstDay) // first day, last month
        var toDate: Date = .now.advanceMonths(by: 0, strategy: .lastDay) // last day, current month
        var accounts: IdentifiedArrayOf<Account>?
        var selectedAccountId: String?
        var showAccountList = false
        var fetchStatus: Action.FetchStatus = .ready
        var popoverFromDate = false
        var popoverToDate = false

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

        var isReportFetching: Bool {
            return fetchStatus == .fetching
        }

        var isReportFetchingLoadingOrErrored: Bool {
            switch fetchStatus {
            case .fetching, .error:
                return true
            case .ready:
                return false
            }
        }

        var fromDateFormatted: String { Date.iso8601Formatter.string(from: fromDate) }
        var toDateFormatted: String { Date.iso8601Formatter.string(from: toDate) }

        func isEqual(to savedReport: SavedReport) -> Bool {
            savedReport.fromDate == fromDateFormatted &&
            savedReport.toDate == toDateFormatted &&
            (savedReport.selectedAccountId == nil || savedReport.selectedAccountId == selectedAccountId)
        }

        /// The fetchTransaction shared code called from elsewhere like the ReportView
        /// It's defined in the state function to allow the shared reuse in a performant type manner.
        /// see https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/performance/#Sharing-logic-with-actions
        mutating func fetchTransactions() -> Effect<ReportInputFeature.Action> {
            guard !isReportFetching else { return .none }
            fetchStatus = .fetching
            let filterBy: BudgetProvider.TransactionParameters.FilterByOption?
            if let selectedId = selectedAccountId, selectedId != Account.allAccountsId {
                filterBy = .account(accountId: selectedId)
            } else {
                filterBy = nil
            }
            let fromDate = self.fromDate
            let toDate = self.toDate
            return .run { send in
                do {
                    @Dependency(\.budgetClient) var budgetClient
                    let transactions = try await budgetClient
                        .fetchTransactions(startDate: fromDate, finishDate: toDate, filterBy: filterBy)
                    await send(.fetchedTransactionsReponse(transactions))
                } catch {
                    let logger = LogFactory.create(category: "ReportInput.State")
                    logger.error("fetch transactions error: - \(error.localizedDescription)")
                }
            }
        }
    }

    enum Action {
        case chartMoreInfoTapped
        case delegate(Delegate)
        case updateFromDateTapped(Date)
        case updateToDateTapped(Date)
        case selectAccountRowTapped(Bool)
        case didSelectAccountId(String?)
        case setPopoverFromDate(Bool)
        case setPopoverToDate(Bool)
        case runReportTapped
        case fetchedTransactionsReponse(IdentifiedArrayOf<TransactionEntry>)
        case onAppear

        @CasePathable
        enum Delegate: Equatable {
            case fetchedTransactions(IdentifiedArrayOf<TransactionEntry>)
            case didUpdateFetchStatus(FetchStatus)
        }

        @CasePathable
        enum FetchStatus: Equatable {
            case ready
            case fetching
            case error(ReportFetchError)
        }
    }

    @Dependency(\.budgetClient) var budgetClient
    let logger = LogFactory.create(category: "ReportInput")

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .chartMoreInfoTapped:
                state.showChartMoreInfo = !state.showChartMoreInfo
                return .none

            case let .setPopoverFromDate(isPresented):
                state.popoverFromDate = isPresented
                return .none

            case let .setPopoverToDate(isPresented):
                state.popoverToDate = isPresented
                return .none

            case .delegate:
                return .none

            case let .updateFromDateTapped(fromDate):
                // if from date is greater than toDate, update toDate to be last day in that month
                if fromDate > state.toDate {
                    state.toDate = fromDate.lastDayInMonth()
                }
                state.fromDate = fromDate
                return .none

            case let .updateToDateTapped(toDate):
                // Ensure date ranges are valid
                let cleanedToDate = toDate < state.fromDate ? state.fromDate.lastDayInMonth() : toDate
                state.toDate = cleanedToDate
                return .none

            case .runReportTapped:
                return state.fetchTransactions()

            case let .fetchedTransactionsReponse(transactions):
                if transactions.isEmpty {
                    state.fetchStatus = .error(.noResults)
                    return .none
                } else {
                    state.fetchStatus = .ready
                    return .send(.delegate(.fetchedTransactions(transactions)), animation: .smooth)
                }

            case let .selectAccountRowTapped(isActive):
                state.showAccountList = isActive
                return .none

            case let .didSelectAccountId(accountId):
                state.selectedAccountId = accountId
                return .none

            case .onAppear:
                if state.accounts == nil {
                    guard budgetClient.accounts.isNotEmpty else { return .none }
                    // by default show transactions for all eligble accounts for the chart type
                    var accounts =  state.chart
                        .eligibleAccountsFiltered(unfilteredAccounts: budgetClient.accounts)
                    let allAccounts = Account.allAccounts
                    if accounts.insert(allAccounts, at: 0).inserted {
                        state.selectedAccountId = allAccounts.id
                    }
                    state.accounts = accounts
                }
                // Ensure provided date is first day of month in FromDate
                // and last day of month ToDate
                state.fromDate = state.fromDate.firstDayInMonth()
                state.toDate = state.toDate.lastDayInMonth()
                return .none
            }
        }
    }
}

// MARK: - View

struct ReportInputView: View {

    @Bindable var store: StoreOf<ReportInputFeature>

    @ScaledMetric(relativeTo: .body) private var chartMoreInfoArrowSize: CGFloat = 5.0
    @ScaledMetric(relativeTo: .body) private var chartImageWidth: CGFloat = 46.0
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 14.0

    var body: some View {
        VStack(spacing: 0) {
            chartAndInputSection

            dateInputSection

            accountSection

            runReportSection
        }
        .backgroundShadow()
        .task {
            store.send(.onAppear)
        }
    }

    var chartAndInputSection: some View {
        VStack {
            VStack(spacing: 0) {
                VStack(spacing: .Spacing.pt12) {
                    HStack(spacing: 0) {
                        // Chart Title and Name
                        VStack(alignment: .leading, spacing: 0) {
                            Text(Strings.chartTitle)
                                .typography(.title2Emphasized)
                                .foregroundStyle(Color.Text.secondary)
                            Text(store.chart.name)
                                .typography(.headlineEmphasized)
                        }
                        Spacer()
                        Spacer()
                        Spacer()
                        // Chart Image
                        store.chart.type.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: chartImageWidth)
                        Spacer()
                    }
                    // More Info
                    VStack {
                        HStack(spacing: .Spacing.pt4) {
                            Button(
                                action: {
                                    store.send(.chartMoreInfoTapped, animation: .default)
                                },
                                label: {
                                    Image(systemName: "arrowtriangle.right.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: chartMoreInfoArrowSize)
                                        .rotationEffect(Angle(degrees: store.showChartMoreInfo ? 90.0 : 0.0))
                                    Text(Strings.moreInfoTitle)
                                        .typography(.bodyEmphasized)
                                }
                            )
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.Text.secondary)
                            Spacer()
                        }
                        // Chart description text when expanded
                        if store.showChartMoreInfo {
                            HStack(spacing: 0) {
                                Text(store.chart.description)
                                    .typography(.body)
                                    .foregroundStyle(Color.Text.secondary)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16.0)
                                    .fill(Color.Surface.tertiary)
                            )
                        }
                    }
                }
                .padding(.Spacing.pt12)
            }
            .background(
                RoundedRectangle(cornerRadius: .Corner.rd8)
                    .fill(Color.clear)
                    .stroke(Color.Border.secondary, lineWidth: 1.0)
            )
        }
        .listRowTop()
    }

    var dateInputSection: some View {
        HStack(alignment: .iconAndTitleAlignment, spacing: .Spacing.pt8) {
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .frame(width: iconWidth)
                .foregroundStyle(Color.Icon.secondary)
                .alignmentGuide(.iconAndTitleAlignment, computeValue: { dimension in
                    dimension[VerticalAlignment.center]
                })

            VStack {
                // From Date
                HStack {
                    Text(Strings.fromDateTitle)
                        .typography(.bodyEmphasized)
                        .alignmentGuide(.iconAndTitleAlignment, computeValue: { dimension in
                            dimension[VerticalAlignment.center]
                        })

                    Spacer()

                    Button {
                        store.send(.setPopoverFromDate(true))
                    } label: {
                        Text(store.fromDate.inputFieldFormat)
                            .typography(.title3Emphasized)
                            .foregroundStyle(Color.Text.primary)
                    }
                    .buttonStyle(.kleonOutlinef(compactWidth: true))
                    .popover(isPresented: $store.popoverFromDate.sending(\.setPopoverFromDate)) {
                        MonthYearPickerView(
                            selection: $store.fromDate.sending(\.updateFromDateTapped), strategy: .firstDay
                        )
                        .presentationCompactAdaptation(.popover)
                    }
                }

                // To Date
                HStack {
                    Text(Strings.toDateTitle)
                        .typography(.bodyEmphasized)

                    Spacer()

                    Button {
                        store.send(.setPopoverToDate(true))
                    } label: {
                        Text(store.toDate.inputFieldFormat)
                            .typography(.title3Emphasized)
                            .foregroundStyle(Color.Text.primary)
                    }
                    .buttonStyle(.kleonOutlinef(compactWidth: true))
                    .popover(isPresented: $store.popoverToDate.sending(\.setPopoverToDate)) {
                        MonthYearPickerView(
                            selection: $store.toDate.sending(\.updateToDateTapped),
                            in: store.fromDate...,
                            strategy: .lastDay
                        )
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
            .foregroundStyle(Color.Text.secondary)
        }
        .listRow()
    }

    var accountSection: some View {
        Button(
            action: {
                store.send(.selectAccountRowTapped(true))
            }, label: {
                HStack(spacing: 0) {
                    HStack(alignment: .iconAndTitleAlignment, spacing: .Spacing.pt8) {
                        Image(systemName: "building.columns.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconWidth)
                            .foregroundStyle(Color.Icon.secondary)
                            .alignmentGuide(
                                .iconAndTitleAlignment,
                                computeValue: { dimension in dimension[VerticalAlignment.center] }
                            )

                        VStack(alignment: .leading, spacing: .Spacing.pt8) {
                            Text(Strings.selectAccountTitle)
                                .typography(.bodyEmphasized)
                                .foregroundStyle(Color.Text.secondary)
                                .alignmentGuide(
                                    .iconAndTitleAlignment,
                                    computeValue: { dimension in dimension[VerticalAlignment.center] }
                                )

                            Text("\(store.selectedAccountName ?? Strings.selectAccountPlaceholder)")
                                .typography(store.isAccountSelected ? .body : .bodyItalic)
                                .foregroundStyle(
                                    store.isAccountSelected ?
                                    Color.Text.primary : Color.Text.secondary
                                )
                        }
                        Spacer()
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.Icon.secondary)
                        .padding(.trailing, .Spacing.pt8)
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
            Button {
                store.send(.runReportTapped, animation: .default)
            } label: {
                ZStack {
                    Text(Strings.runReportTitle)
                        .typography(.title3Emphasized)
                        .opacity(store.isReportFetching ? 0 : 1)
                    ProgressView()
                        .tint(Color.Button.primaryTitle)
                        .opacity(store.isReportFetching ? 1 : 0)
                }
            }
            .buttonStyle(.kleonPrimary)
            .disabled(store.isRunReportDisabled)
            .containerRelativeFrame(.horizontal) { length, _ in
                length * 0.7
            }
        }
        .listRowBottom()
    }

}

// MARK: - Strings

private enum Strings {
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

// MARK: - Private

private extension Date {
    static func aWeekFrom(_ date: Date) -> Date {
        .init(timeInterval: TimeInterval(60*60*24*6), since: date)
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

// MARK: - Preview

#Preview {
    ScrollView {
        ReportInputView(
            store: Store(
                initialState: ReportInputFeature.State(chart: .mock, accounts: .mocks)
            ) {
                ReportInputFeature()
            }
        )
    }
    .contentMargins(.all, .Spacing.pt16, for: .scrollContent)
    .background(Color.Surface.primary)
}
