// Created by Daniel Amoafo on 5/5/2024.

import Dependencies
import Foundation
import SwiftData

struct Database {
    var swiftData: ModelContext
    var grdb: GRDBDatabase

    init(swiftData: @escaping () throws -> ModelContext, grdb: @escaping () throws -> GRDBDatabase) {
        do {
            self.swiftData = try swiftData()
            self.grdb = try grdb()
        } catch {
            let logger = LogFactory.create(category: "Database init")
            logger.error("Unable init Database instance...")
            fatalError("\(error.toString())")
        }
    }
}

extension Database: DependencyKey {

    static let liveValue = Self(
        swiftData: { try ModelContextFactory.makeLive() },
        grdb: { try GRDBDatabase.makeLive() }
    )

    static let testValue = Self(
        swiftData: { try ModelContextFactory.makeMock() },
        grdb: { try GRDBDatabase.makeMock() }
    )

    static let previewValue = Self(
        swiftData: { try ModelContextFactory.makeMock() },
        grdb: { try GRDBDatabase.makeMock() }
    )

}

extension DependencyValues {
    var database: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}
