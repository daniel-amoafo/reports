// Created by Daniel Amoafo on 15/4/2024.

import BudgetSystemService
import ComposableArchitecture
import SwiftUI

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
                Text(Strings.runReportTitle)
                    .typography(.title3Emphasized)
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
