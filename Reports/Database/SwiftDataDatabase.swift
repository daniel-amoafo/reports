// Created by Daniel Amoafo on 17/5/2024.

import Foundation
import SwiftData

enum SwiftDataDatabase {

    static func makeLive() throws -> ModelContext {
        let savedReport = ModelConfiguration("SavedReportModelConfig", schema: Schema([SavedReport.self]))

        let container = try ModelContainer(for: SavedReport.self, configurations: savedReport)
        return ModelContext(container)
    }

    static func makeMock() throws -> ModelContext {
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
    }

}
