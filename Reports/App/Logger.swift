// Created by Daniel Amoafo on 22/2/2024.

import Foundation
import OSLog

struct LogFactory {

    enum Category: String {
        case appFeature = "AppFeature"
        case login = "Login"
        case home = "Home"
    }

    static func create(category: Category) -> Logger {
        create(category: category.rawValue)
    }

    static func create(category: String) -> Logger {
        .init(subsystem: "Reports", category: category)
    }
}
