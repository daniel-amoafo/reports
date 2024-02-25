// Created by Daniel Amoafo on 22/2/2024.

import Foundation
import OSLog

struct LogFactory {

    enum Category: String {
        case appFeature = "AppFeature"
        case login = "Login"
    }

    static func create(category: Category) -> Logger {
        .init(subsystem: "Reports", category: category.rawValue)
    }
}
