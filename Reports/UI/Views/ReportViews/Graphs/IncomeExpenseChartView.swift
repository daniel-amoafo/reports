// Created by Daniel Amoafo on 3/3/2026.

import BudgetSystemService
import Charts
import ComposableArchitecture
import MoneyCommon
import SwiftUI

struct IncomeExpenseChartView: View {
    @Bindable var store: StoreOf<IncomeExpenseChartFeature>

    var body: some View {
        Group {
            if let data = store.reportData {
                mainContent(data: data)
            } else {
                ProgressView()
                    .onAppear {
                        store.send(.onAppear)
                    }
            }
        }
    }
}

private extension IncomeExpenseChartView {

    func mainContent(data: IncomeExpenseReportData) -> some View {
        VStack(spacing: .Spacing.pt24) {
            header(data: data)

            summaryCards(data: data)

            chartSection(data: data)

            // Transactions list could be added here later
        }
    }

    func header(data: IncomeExpenseReportData) -> some View {
        ZStack {
            KleonGradient.purpleDusk
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 4) {
                Text("Financial Report")
                    .typography(.title3Emphasized)
                    .foregroundStyle(.white)
                Text("Track your income & expenses")
                    .typography(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    func summaryCards(data: IncomeExpenseReportData) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Total Income",
                    amount: data.totalIncome.amountFormatted,
                    trend: data.incomePercentageChange,
                    icon: "arrow.up.right",
                    iconColor: Color(hex: "#10b981")
                )

                SummaryCard(
                    title: "Total Expenses",
                    amount: data.totalExpenses.amountFormatted,
                    trend: data.expensePercentageChange,
                    icon: "arrow.down.left",
                    iconColor: Color(hex: "#ef4444"),
                    isNegativeTrend: true
                )
            }

            SummaryCard(
                title: "Net Balance",
                amount: data.netBalance.amountFormatted,
                trend: nil,
                icon: "wallet.pass",
                iconColor: Color(hex: "#6418c3")
            )
        }
    }

    func chartSection(data: IncomeExpenseReportData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trend Analysis")
                    .typography(.headlineEmphasized)
                Spacer()
                Picker("Chart Type", selection: $store.chartType) {
                    ForEach(IncomeExpenseChartFeature.State.ChartToggleType.allCases) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            chart(data: data)
                .frame(height: 250)
        }
        .padding()
        .background(Color.Surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    func chart(data: IncomeExpenseReportData) -> some View {
        let allTrends = data.incomeTrends + data.expenseTrends

        Chart {
            ForEach(allTrends) { record in
                if store.chartType == .bar {
                    BarMark(
                        x: .value("Date", record.date, unit: .month),
                        y: .value("Amount", record.total.amount)
                    )
                    .foregroundStyle(by: .value("Type", record.name))
                    .position(by: .value("Type", record.name))
                } else {
                    LineMark(
                        x: .value("Date", record.date, unit: .month),
                        y: .value("Amount", record.total.amount)
                    )
                    .foregroundStyle(by: .value("Type", record.name))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", record.date, unit: .month),
                        y: .value("Amount", record.total.amount)
                    )
                    .foregroundStyle(by: .value("Type", record.name))
                    .opacity(0.1)
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartForegroundStyleScale([
            "Income": Color(hex: "#10b981"),
            "Expense": Color(hex: "#ef4444"),
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: String
    let trend: Double?
    let icon: String
    let iconColor: Color
    var isNegativeTrend: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .foregroundStyle(iconColor)
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(title)
                        .typography(.subheadline)
                        .foregroundStyle(Color.Text.secondary)
                }

                Text(amount)
                    .typography(.headlineEmphasized)
                    .foregroundStyle(Color.Text.primary)

                if let trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                        Text("\(abs(trend), specifier: "%.1f")% vs last period")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(trend >= 0 ? (isNegativeTrend ? .red : .green) : (isNegativeTrend ? .green : .red))
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.Surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
