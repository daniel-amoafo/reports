// Created by Daniel Amoafo on 17/5/2024.

import Foundation
import SwiftData

enum ModelContextFactory {

    static func makeLive() throws -> ModelContext {
        let savedReport = ModelConfiguration("SavedReportModelConfig", schema: schema)

        let container = try ModelContainer(for: schema, configurations: savedReport)
        return ModelContext(container)
    }

    static func makeMock(insertSampleData: Bool) throws -> ModelContext {
        let savedReport = ModelConfiguration(for: SavedReport.self, isStoredInMemoryOnly: true)

        let container = try ModelContainer(for: schema, configurations: savedReport)
        let context = ModelContext(container)
        if insertSampleData {
            do {
                try MockData.insertSavedReport(context)
            } catch {
                debugPrint(error)
            }
        }
        return context
    }

    private static var schema: Schema {
        Schema([SavedReport.self])
    }

}
