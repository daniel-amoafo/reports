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
    static let testValue = Self(
        context: { testContext }
    )

    @MainActor
    static let previewValue = Self(
        context: { previewsContext }
    )
}

extension DependencyValues {
    var database: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}

// MARK: -

private let liveContext: ModelContext = {
    do {
        let savedReport = ModelConfiguration("SavedReportModelConfig", schema: Schema([SavedReport.self]))

        let container = try ModelContainer(for: SavedReport.self, configurations: savedReport)
        let ctx = ModelContext(container)
        ctx.autosaveEnabled = false
        return ctx
    } catch {
        fatalError("Failed to create swift data live container - \(error.localizedDescription)")
    }
}()

@MainActor
private var testContext: ModelContext {
    unimplemented("\(ModelContext.self).context")
}

@MainActor
private var previewsContext: ModelContext {
    do {
        let savedReport = ModelConfiguration(for: SavedReport.self, isStoredInMemoryOnly: true)

        let container = try ModelContainer(for: SavedReport.self, configurations: savedReport)
        let context = ModelContext(container)
        for report in SavedReport.previews {
            context.insert(report)
        }
        do {
            try context.save()
        } catch {
            debugPrint("\(error.localizedDescription)")
        }
        return ModelContext(container)
    } catch {
        fatalError("Failed to create swift data test container - \(error.localizedDescription)")
    }
}
