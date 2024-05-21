// Created by Daniel Amoafo on 21/4/2024.

import Foundation

public extension Date {

    /// Formats date using ISO8601 standard to the UTC timezone.
    static let iso8601utc: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    /// Formats date using ISO8601 standard to the devices current timezone.
    static let iso8601local: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = NSTimeZone.local
        return formatter
    }()

}
