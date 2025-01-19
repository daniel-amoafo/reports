// Created by Daniel Amoafo on 26/5/2024.

import CoreData
import Dependencies
import Foundation
import SwiftData

struct ModelContextNotifications {

    var didUpdate: @Sendable ((any PersistentModel.Type)?) async -> AsyncStream<Void>
}

extension DependencyValues {

    var modelContextNotifications: ModelContextNotifications {
        get { self[ModelContextNotifications.self] }
        set { self[ModelContextNotifications.self] = newValue }
    }
}

extension ModelContextNotifications: DependencyKey {

    static let liveValue = Self.impl

    static let testValue = Self.impl
}

// MARK: -

private extension ModelContextNotifications {

    private static let impl = Self { modelType in
        AsyncStream(
            UncheckedSendable(NotificationCenter.default
            // Should use ModelContext.didSave notificaion name
            // however due to be a bug as of iOS17.4, it does not fire when modelContext saved operation runs.
            // see https://developer.apple.com/forums/thread/731378
                .notifications(named: .NSManagedObjectContextDidSave)
                .filter {

                    // If no modelType is specified, will send notifications for any context changes.
                    guard let modelType else { return true }

                    // filter notifications to Model Type entries being inserted/updated or deleted
                    if let insertedObjects: Set<NSManagedObject> = $0.insertedObjects,
                       insertedObjects
                        .map(\.entity.name)
                        .contains(String(describing: modelType)) {
                        return true
                    }

                    if let deletedObjects: Set<NSManagedObject> = $0.deletedObjects,
                       deletedObjects
                        .map(\.entity.name)
                        .contains(String(describing: modelType)) {
                        return true
                    }

                    if let updatedObjects: Set<NSManagedObject> = $0.updatedObjects,
                       updatedObjects
                        .map(\.entity.name)
                        .contains(String(describing: modelType)) {
                        return true
                    }

                    // Save notification did not include inserted or deleted objects
                    return false
                }
                .map { _ in })
        )
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

    var updatedObjects: Set<NSManagedObject>? {
        return userInfo?.value(for: .updatedObjects)
    }
}

private extension Dictionary where Key == AnyHashable {
  func value<T>(for key: NSManagedObjectContext.NotificationKey) -> T? {
    return self[key.rawValue] as? T
  }
}
