// Created by Daniel Amoafo on 5/5/2024.

import CoreData
import Dependencies
import Foundation
import OSLog
import SwiftData

/// Provides Database CRUD operations for the `SavedReport` data model object.
struct SavedReportQuery: Sendable {
    var fetchAll: @Sendable () throws -> [SavedReport]
    var fetch: @Sendable (FetchDescriptor<SavedReport>) throws -> [SavedReport]
    var fetchOne: @Sendable (UUID) throws -> SavedReport
    var fetchCount: @Sendable (FetchDescriptor<SavedReport>) throws -> Int
    var add: @Sendable (SavedReport) throws -> Void
    var delete: @Sendable (SavedReport) throws -> Void

    enum SavedReportQueryError: Error {
        case add(String)
        case delete(String)
        case notFound(String)
    }
}

extension SavedReportQuery: DependencyKey {

    static let liveValue = Self.impl
    // tests & previews use an in memory modelContext so data is not written to a persistent database.
    static let testValue = Self.impl
    static let previewValue = Self.impl

}

private extension SavedReportQuery {

    private static var logger: Logger { LogFactory.create(category: "SavedReportQuery") }

    private static var modelContext: ModelContext {
        @Dependency(\.database.swiftData) var context
        return context
    }

    private static let impl = Self {
        do {
            let descriptor = FetchDescriptor<SavedReport>(
                sortBy: [SortDescriptor(\.lastModifield, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("\(error.toString())")
            return []
        }
    } fetch: { descriptor in
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("\(error.toString())")
            return []
        }
    } fetchOne: { id in
        let descriptor = FetchDescriptor<SavedReport>(
            predicate: #Predicate<SavedReport> { savedReport in
                savedReport.id == id
            }
        )
        guard let savedReport = try modelContext.fetch(descriptor).first else {
            let msg = "Unable to find savedReport with id: \(id)"
            logger.error("\(msg)")
            throw SavedReportQueryError.notFound(msg)
        }
        return savedReport

    } fetchCount: { descriptor in
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            logger.error("\(error.toString())")
            return 0
        }
    } add: { savedReport in
        do {
            modelContext.insert(savedReport)
            try modelContext.save()
        } catch {
            logger.error("\(error.toString())")
            throw SavedReportQueryError.add(error.toString())
        }
    } delete: { savedReport in
        do {
            modelContext.delete(savedReport)
            try modelContext.save()
        } catch {
            logger.error("\(error.toString())")
            throw SavedReportQueryError.delete(error.toString())
        }
    }
}

extension DependencyValues {
    var savedReportQuery: SavedReportQuery {
        get { self[SavedReportQuery.self] }
        set { self[SavedReportQuery.self] = newValue }
    }
}

// MARK: - Core Data / Notification Syntax Management

private extension Notification {
    var insertedObjects: Set<NSManagedObject>? {
        return userInfo?.value(for: .insertedObjects)
    }

    var deletedObjects: Set<NSManagedObject>? {
        return userInfo?.value(for: .deletedObjects)
    }
}

private extension Dictionary where Key == AnyHashable {
  func value<T>(for key: NSManagedObjectContext.NotificationKey) -> T? {
    return self[key.rawValue] as? T
  }
}
