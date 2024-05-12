// Created by Daniel Amoafo on 5/5/2024.

import Dependencies
import Foundation
import SwiftData

struct Database {
    var context: () throws -> ModelContext
}

extension Database: DependencyKey {

    @MainActor
    static let liveValue = {
        Self(
            context: {
                do {
                    let savedReport = ModelConfiguration("SavedReportModelConfig", schema: Schema([SavedReport.self]))

                    let container = try ModelContainer(for: SavedReport.self, configurations: savedReport)
                    return ModelContext(container)
                } catch {
                    fatalError("Failed to create swift data live container - \(error.localizedDescription)")
                }
            }
        )
    }()

    @MainActor
    static let testValue = Self(
        context: { mockContext }
    )

    @MainActor
    static let previewValue = Self(
        context: { mockContext }
    )
}

extension DependencyValues {
    var database: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}

// MARK: -

@MainActor
private let mockContext: ModelContext = {
    do {
        let savedReport = ModelConfiguration(for: SavedReport.self, isStoredInMemoryOnly: true)

        let container = try ModelContainer(for: SavedReport.self, configurations: savedReport)
        let context = ModelContext(container)
        for report in SavedReport.mocks {
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
}()
