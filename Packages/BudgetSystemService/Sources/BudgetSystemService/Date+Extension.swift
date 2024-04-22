// Created by Daniel Amoafo on 21/4/2024.

import Foundation

public extension Date {

    static var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = NSTimeZone.local
        return formatter
    }()

}
