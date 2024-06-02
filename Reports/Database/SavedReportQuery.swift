// Created by Daniel Amoafo on 5/5/2024.

import CoreData
import Dependencies
import Foundation
import OSLog
import SwiftData

/// Provides Database CRUD operations for the `SavedReport` data model object.
struct SavedReportQuery {
    var fetchAll: @Sendable () throws -> [SavedReport] // fix fetch only a budgetId
    var fetch: @Sendable (FetchDescriptor<SavedReport>) throws -> [SavedReport]
    var fetchCount: @Sendable (FetchDescriptor<SavedReport>) throws -> Int
    var add: @Sendable (SavedReport) throws -> Void
    var delete: @Sendable (SavedReport) throws -> Void

    enum SavedReportQueryError: Error {
        case add(String)
        case delete(String)
    }
}

extension SavedReportQuery: DependencyKey {

    static let liveValue = Self.live

    static let testValue = Self(
        fetchAll: unimplemented("\(Self.self).fetch"),
        fetch: unimplemented("\(Self.self).fetchDescriptor"),
        fetchCount: unimplemented("\(Self.self).fetchCountDescriptor"),
        add: unimplemented("\(Self.self).add"),
        delete: unimplemented("\(Self.self).delete")
    )

    // Previews use an in memory modelContext so data is not written to a persistent database.
    static var previewValue = Self.live
}

private extension SavedReportQuery {

    private static var logger: Logger { LogFactory.create(category: "SavedReportQuery") }

    private static var modelContext: ModelContext {
        @Dependency(\.database.swiftData) var context
        return context
    }

    private static let live = Self {
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
