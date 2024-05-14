// Created by Daniel Amoafo on 13/5/2024.

import SwiftUI

struct MonthYearPickerView: View {
    @Binding var selection: Date
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    private var minimumDate: Date
    private var maximumDate: Date
    private var months: [String]
    private var years: [Int] = []
    private let strategy: DateStrategy

    private var availableYears: [Int] {
        let minYear = Calendar.current.component(.year, from: minimumDate)
        let maxYear = Calendar.current.component(.year, from: maximumDate)
        return Array(minYear...maxYear)
    }

    init(selection: Binding<Date>, strategy: DateStrategy) {
        self.init(selection: selection, in: Date.distantPast...Date.distantFuture, strategy: strategy)
    }

    init(selection: Binding<Date>, in dateFrom: PartialRangeFrom<Date>, strategy: DateStrategy) {
        self.init(selection: selection, in: dateFrom.lowerBound...Date.distantFuture, strategy: strategy)
    }

    init(selection: Binding<Date>, in dateRange: ClosedRange<Date>, strategy: DateStrategy) {
        self.minimumDate = dateRange.lowerBound
        self.maximumDate = dateRange.upperBound
        self.selectedMonth = Self.get(.month, from: selection.wrappedValue)
        self.selectedYear = Self.get(.year, from: selection.wrappedValue)
        self._selection = selection
        self.strategy = strategy
        self.months = Calendar.current.monthSymbols.map { $0.capitalized }
        self.years = availableYears
    }

    var body: some View {
        HStack {
            Picker("Month", selection: $selectedMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text(self.months[month - 1]).tag(month)
                }
            }
            .pickerStyle(.wheel)

            Picker("Year", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    Text(verbatim: "\(year)").tag(year)
                }
            }
            .pickerStyle(.wheel)
        }
        .scaledToFit()
        .onChange(of: selectedMonth) {
            refreshSelectedDate()
        }
        .onChange(of: selectedYear) {
            refreshSelectedDate()
        }
        .onAppear {
            selection = strategy.dateFor(year: selectedYear, month: selectedMonth)
        }
    }

    private func refreshSelectedDate() {
        let date = strategy.dateFor(year: selectedYear, month: selectedMonth)
        if date < minimumDate {
            selectedYear = Calendar.current.component(.year, from: minimumDate)
            selectedMonth = Calendar.current.component(.month, from: minimumDate)
        } else if date > maximumDate {
            selectedYear = Calendar.current.component(.year, from: maximumDate)
            selectedMonth = Calendar.current.component(.month, from: maximumDate)
        } else {
            selection = date
        }
    }

    private static func get(_ component: Calendar.Component, from date: Date) -> Int {
        Calendar.current.component(component, from: date)
    }
}

extension MonthYearPickerView {

}

// MARK: -

 #Preview {
     ContentView()
 }

private struct ContentView: View {

    @State private var fromDate: Date = .now
    @State private var toDate: Date = .now.advanceMonths(by: 1, strategy: .lastDay)

    var body: some View {
        VStack {
            Text(Date.iso8601Formatter.string(from: fromDate))
            MonthYearPickerView(selection: $fromDate, strategy: .firstDay)

            Divider()

            Text(Date.iso8601Formatter.string(from: toDate))
            MonthYearPickerView(selection: $toDate, in: fromDate..., strategy: .lastDay)
        }
    }
}
