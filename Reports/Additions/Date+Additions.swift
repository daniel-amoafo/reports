// Created by Daniel Amoafo on 14/5/2024.

import Foundation

extension Date {

    var inputFieldFormat: String {
        "\(self.formatted(.dateTime.month())) \(self.formatted(.dateTime.year()))"
    }

    func advanceMonths(by val: Int, strategy: DateStrategy? = nil) -> Date {

        guard let aDate = Calendar.current.date(byAdding: .month, value: val, to: self) else {
            fatalError("Unable to resolve to a valid date")
        }

        guard let strategy else {
            return aDate
        }

        return DateStrategy.dateFor(aDate, strategy: strategy)
    }

    func firstDayInMonth() -> Date {
        DateStrategy.dateFor(self, strategy: .firstDay)
    }

    func lastDayInMonth() -> Date {
        DateStrategy.dateFor(self, strategy: .lastDay)
    }

}

enum DateStrategy {
    case firstDay
    case lastDay

    /// Create a complete date using the first or last day for the selected year & month.
    func dateFor(year: Int, month: Int) -> Date {
        guard let aDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) else {
            fatalError("\(#function) Unable to get first date from year/month (\(year)/\(month)")
        }
        return Self.dateFor(aDate, strategy: self)
    }

    static func dateFor(_ date: Date, strategy: DateStrategy) -> Date {
        let month = get(.month, from: date)
        let year = get(.year, from: date)
        guard let dateFirstDay = Calendar.current.date(
            from: DateComponents(year: year, month: month, day: 1)
        ) else {
            fatalError("\(#function) Unable to get first date from year/month (\(year)/\(month)")
        }

        switch strategy {
        case .firstDay:
            return dateFirstDay
        case .lastDay:
            guard let dateLastDay = Calendar.current
                .date(byAdding: DateComponents(month: 1, day: -1), to: dateFirstDay) else {
                fatalError("Unable to get last date from year/month (\(year)/\(month)")
                    }
            return dateLastDay
        }
    }

    static func get(_ component: Calendar.Component, from date: Date) -> Int {
        Calendar.current.component(component, from: date)
    }
}
