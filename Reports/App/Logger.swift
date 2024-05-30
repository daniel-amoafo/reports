// Created by Daniel Amoafo on 22/2/2024.

import Foundation
import OSLog

struct LogFactory {

    static func create(category: String) -> Logger {
        .init(subsystem: "Reports", category: category)
    }

    static func create(_ category: Any) -> Logger {
        Self.create(category: String(describing: category.self))
    }
}
