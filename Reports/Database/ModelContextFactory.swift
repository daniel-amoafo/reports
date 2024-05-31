// Created by Daniel Amoafo on 17/5/2024.

import Foundation
import SwiftData

enum ModelContextFactory {

    static func makeLive() throws -> ModelContext {
        let savedReport = ModelConfiguration("SavedReportModelConfig", schema: schema)

        let container = try ModelContainer(for: schema, configurations: savedReport)
        return ModelContext(container)
    }

    static func makeMock() throws -> ModelContext {
        let savedReport = ModelConfiguration(for: SavedReport.self, isStoredInMemoryOnly: true)

        let container = try ModelContainer(for: schema, configurations: savedReport)
        let context = ModelContext(container)
        for report in SavedReport.mocks {
            context.insert(report)
        }
        do {
            try context.save()
        } catch {
            debugPrint("\(error.toString())")
        }
        return ModelContext(container)
    }

    private static var schema: Schema {
        Schema([SavedReport.self])
    }

}
