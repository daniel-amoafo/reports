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
        var fromDate: Date = .now
        var toDate: Date = .aWeekFrom(.now)
        var accounts: IdentifiedArrayOf<Account>?
        var selectedAccountId: String?
        var showAccountList = false
        var fetchStatus: Action.FetchStatus = .ready

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
    }

    enum Action {
        case chartMoreInfoTapped
        case delegate(Delegate)
        case updateFromDateTapped(Date)
        case updateToDateTapped(Date)
        case selectAccountRowTapped(Bool)
        case didSelectAccountId(String?)
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

            case .delegate:
              return .none

            case let .updateFromDateTapped(fromDate):
                state.fromDate = fromDate
                return .none

            case let .updateToDateTapped(toDate):
                state.toDate = toDate
                return .none

            case .runReportTapped:
                guard !state.isReportFetching else { return .none }
                state.fetchStatus = .fetching
                return .run { [state] send in
                    await fetchTransactions(state: state, send: send)
                }

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
                    // by default show transactions for all eligble accounts
                    var accounts = budgetClient.accounts
                    let allAccounts = Account.allAccounts
                    if accounts.insert(allAccounts, at: 0).inserted {
                        state.selectedAccountId = allAccounts.id
                    }
                    state.accounts = accounts
                }
                return .none
            }
        }
    }
}

private extension ReportInputFeature {

    func fetchTransactions(state: ReportInputFeature.State, send: Send<ReportInputFeature.Action>) async {
        do {
            var filterBy: BudgetProvider.TransactionParameters.FilterByOption?
            if let selectedId = state.selectedAccountId, selectedId != Account.allAccountsId {
                filterBy = .account(accountId: selectedId)
            }
            let transactions = try await budgetClient
                .fetchTransactions(startDate: state.fromDate, finishDate: state.toDate, filterBy: filterBy)
            await send(.fetchedTransactionsReponse(transactions))
        } catch {
            logger.error("error: - \(error.localizedDescription)")
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
