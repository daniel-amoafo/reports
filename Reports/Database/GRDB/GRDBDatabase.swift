// Created by Daniel Amoafo on 16/5/2024.

import BudgetSystemService
import Foundation
import GRDB
import IdentifiedCollections

struct GRDBDatabase {

    /// Provides access to the database.
    private let dbWriter: any DatabaseWriter

    /// Creates an `GRDBDatabase`, and makes sure the database schema
    /// is ready.
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
}

extension GRDBDatabase {

    enum ValidationError: LocalizedError {
        case missingBudgetId

        var errorDescription: String? {
            switch self {
            case .missingBudgetId:
                return "A valid budget id is required"
            }
        }
    }
}

// MARK: - Database Configuration

extension GRDBDatabase {
    private static let logger = LogFactory.create(Self.self)

    /// Returns a database configuration suited for `PlayerRepository`.
    ///
    /// SQL statements are logged if the `SQL_TRACE` environment variable
    /// is set.
    ///
    /// - parameter base: A base configuration.
    public static func makeConfiguration(_ base: Configuration = Configuration()) -> Configuration {
        var config = base

        // An opportunity to add required custom SQL functions or
        // collations, if needed:
        // config.prepareDatabase { db in
        //     db.add(function: ...)
        // }

        // Log SQL statements if the `SQL_TRACE` environment variable is set.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/database/trace(options:_:)>
        if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
            config.prepareDatabase { db in
                db.trace {
                    // It's ok to log statements publicly. Sensitive
                    // information (statement arguments) are not logged
                    // unless config.publicStatementArguments is set
                    // (see below).
                    logger.debug("SQL: \($0)")
                }
            }
        }

#if DEBUG
        // Protect sensitive information by enabling verbose debugging in
        // DEBUG builds only.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/configuration/publicstatementarguments>
        config.publicStatementArguments = true
#endif

        return config
    }
}

// MARK: - GRDBDatabase Instance Creation

extension GRDBDatabase {

    /// Used by a simulator and device builds. The normal operating mode in the app.
    static func makeLive() throws -> Self {
        // Create the "Application Support/Database" directory if needed
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)

        // Support for tests: delete the database if requested
        if CommandLine.arguments.contains("-reset") {
            try? fileManager.removeItem(at: directoryURL)
        }

        // Create the database folder if needed
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        // Open or create the database
        let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
        logger.debug("Database stored at \(databaseURL.path)")
        let dbPool = try DatabasePool(
            path: databaseURL.path,
            // Use default GRDBDatabase configuration
            configuration: Self.makeConfiguration()
        )

        // Create the GRDBDatabase
        let database = try Self(dbPool)

        return database
    }

    /// Used by Unit tests and Preview builds.
    static func makeMock(insertSampleData: Bool) throws -> Self {
        // Connect to an in-memory database
        let dbQueue = try DatabaseQueue(configuration: Self.makeConfiguration())
        let instance = try Self(dbQueue)
        if insertSampleData {
            do {
                try MockData.insertSampleData(grdb: instance)
            } catch {
                debugPrint(error)
            }
        }
        return instance
    }
}

// MARK: - Database Migrations

private extension GRDBDatabase {

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

#if DEBUG
        // Speed up development by nuking the database when migrations change
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
        migrator.eraseDatabaseOnSchemaChange = true
#endif
// swiftlint:disable identifier_name

        migrator.registerMigration("create initial tables") { db in
            // Create a tables
            // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseschema>
            try db.create(table: "budgetSummary") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("lastModifiedOn", .text).notNull()
                t.column("firstMonth", .text).notNull()
                t.column("lastMonth", .text).notNull()
                t.column("currencyCode", .text).notNull()
            }

            try db.create(table: "account") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("onBudget", .boolean).notNull()
                t.column("closed", .boolean).notNull()
                t.column("deleted", .boolean).notNull()
                t.belongsTo("budgetSummary", onDelete: .cascade).notNull()
            }

            try db.create(table: "categoryGroup") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("hidden", .boolean).notNull()
                t.column("deleted", .boolean).notNull()
                t.belongsTo("budgetSummary", onDelete: .cascade).notNull()
            }

            try db.create(table: "category") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("hidden", .boolean).notNull()
                t.column("deleted", .boolean).notNull()
                t.belongsTo("categoryGroup", onDelete: .cascade).notNull()
                t.belongsTo("budgetSummary", onDelete: .cascade).notNull()
            }

            try db.create(table: "transactionEntry") { t in
                t.primaryKey("id", .text).notNull()
                t.column("date", .date).notNull()
                t.column("amount", .integer).notNull()
                t.column("currencyCode", .text).notNull()
                t.column("payeeName", .text)
                t.column("accountId", .text).notNull()
                t.column("accountName", .text).notNull()
                t.column("categoryId", .text)
                t.column("categoryName", .text)
                t.column("transferAccountId", .text)
                t.column("deleted", .boolean)
                t.belongsTo("budgetSummary", onDelete: .cascade).notNull()
            }

            try db.create(table: "serverKnowledgeConfig") { t in

                t.belongsTo("budgetSummary", onDelete: .cascade)
                    .unique()
                    .notNull()

                // The last known server knowledge values per api
                t.column("categories", .integer)
                t.column("transactions", .integer)
            }
        }

        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }

        return migrator
    }
// swiftlint:enable identifier_name
}

// MARK: - Database Save

extension GRDBDatabase {

    func save(record: PersistableRecord) throws {
        try save(records: [record])
    }

    func save(records: [any PersistableRecord]) throws {
        try dbWriter.write { db in
            for record in records {
                try record.save(db)
            }
        }
    }

    func save(records: [PersistableRecord], in db: GRDB.Database) throws {
        for record in records {
            try record.save(db)
        }
    }
}

// MARK: - Perform

extension GRDBDatabase {

    func perform(perform: @Sendable @escaping (GRDB.Database) throws -> Void) throws {
        try dbWriter.write { db in
            try perform(db)
        }
    }

    func perform(perform: @Sendable @escaping (GRDB.Database) throws -> Void) async throws {
        try await dbWriter.write { db in
            try perform(db)
        }
    }
}

// MARK: - Database Access: Fetch

extension GRDBDatabase {

    /// Fetch one record using a `FetchRequest`.
    func fetchRecord<Record: FetchableRecord>(_ record: Record.Type, request: any FetchRequest) throws -> Record? {
        try dbWriter.read { db in
            try record.fetchOne(db, request)
        }
    }

    /// Fetch all records using for the provided Record type.
    func fetchAllRecords<Record: FetchableRecord & TableRecord>(_ record: Record.Type)
    throws -> [Record] {
        try dbWriter.read { db in
            try record.fetchAll(db)
        }
    }

    /// Fetch records using a `FetchRequest`.
    func fetchRecords<Record: FetchableRecord>(_ record: Record.Type, request: any FetchRequest) throws -> [Record] {
        try dbWriter.read { db in
            try record.fetchAll(db, request)
        }
    }

    /// Fetch records using `RecordSQLBuilder`.
    func fetchRecords<Record: FetchableRecord>(builder: RecordSQLBuilder<Record>) throws -> [Record] {
        try dbWriter.read { db in
            let sql = builder.sql
            let arguments = StatementArguments(builder.arguments)
            return try builder.record.fetchAll(db, sql: sql, arguments: arguments)
        }
    }

}

extension GRDBDatabase {

    /// A struct used to create a SQL to return a record type.
    /// Maybe mislabelled as it's following a Builder pattern, revisit to see if it be made into a builder/
    struct RecordSQLBuilder<Record: FetchableRecord> {
        let record: Record.Type
        let sql: String
        let arguments: [String: (any DatabaseValueConvertible)?]
    }

}
