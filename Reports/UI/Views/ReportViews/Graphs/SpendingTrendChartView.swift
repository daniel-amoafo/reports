// Created by Daniel Amoafo on 13/5/2024.

import BudgetSystemService
import Charts
import ComposableArchitecture
import MoneyCommon
import SwiftUI

// MARK: - View

struct SpendingTrendChartView: View {

    var body: some View {
        VStack {
            chart
            Spacer()
        }
    }

}

private extension SpendingTrendChartView {

    var chart: some View {
        Chart(TxItem.data) { item in
            BarMark(
                x: .value("Date", item.date, unit: .month),
                y: .value("Amount", item.value)
            )
            .foregroundStyle(by: .value("Category", item.category))
        }
        .scaledToFit()
    }
}

struct TxItem: Identifiable {

    static let date = Date.iso8601Formatter
    let id: String = UUID().uuidString
    let date: Date
    let category: String
    let value: Int

    static var data: [TxItem] = [
        .init(date: date.date(from: "2024-03-01")!, category: "Food", value: 10),
        .init(date: date.date(from: "2024-03-02")!, category: "Rent", value: 40),
        .init(date: date.date(from: "2024-05-04")!, category: "Transport", value: 25),
        .init(date: date.date(from: "2024-03-04")!, category: "Food", value: 20),
    ]
}

// MARK: -

#Preview {
    SpendingTrendChartView()
        .padding()
}
