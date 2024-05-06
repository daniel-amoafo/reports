// Created by Daniel Amoafo on 5/5/2024.

import Dependencies
import Foundation
import SwiftData

struct Database {
    var context: () throws -> ModelContext
}

extension Database: DependencyKey {

    @MainActor
    static let liveValue = Self(
        context: { liveContext }
    )

    @MainActor
    static var testValue = Self {
        testContext
    }

    @MainActor
    static var previewValue = Self {
        testContext
    }
}

extension DependencyValues {
    var database: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}

// MARK: -

@MainActor
private let liveContext: ModelContext = {
    do {
        let savedReport = ModelConfiguration("SavedReportModelConfig", schema: Schema([SavedReport.self]))

        let container = try ModelContainer(for: SavedReport.self, configurations: savedReport)
        return ModelContext(container)
    } catch {
        fatalError("Failed to create swift data live container - \(error.localizedDescription)")
    }
}()

@MainActor
private var testContext: ModelContext {
    do {
        let savedReport = ModelConfiguration(for: SavedReport.self, isStoredInMemoryOnly: true)

        let container = try ModelContainer(configurations: savedReport)
        return ModelContext(container)
    } catch {
        fatalError("Failed to create swift data test container - \(error.localizedDescription)")
    }
}
