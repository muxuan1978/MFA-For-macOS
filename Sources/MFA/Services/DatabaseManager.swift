import Foundation
import GRDB

enum DatabaseManager {
    private static let dbName = "mfa.sqlite"

    static func openDatabase(at path: String? = nil) throws -> DatabasePool {
        let dbPath: String
        if let path {
            dbPath = path
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("MFA", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            dbPath = dir.appendingPathComponent(dbName).path
        }

        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode=WAL")
        }

        let dbPool = try DatabasePool(path: dbPath, configuration: config)
        try migrate(dbPool)
        return dbPool
    }

    static func openInMemory() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        try migrate(dbQueue)
        return dbQueue
    }

    private static func migrate(_ dbWriter: any DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_create_account") { db in
            try db.create(table: Account.databaseTableName) { t in
                t.column("id", .text).primaryKey()
                t.column("issuer", .text).notNull()
                t.column("accountName", .text).notNull()
                t.column("encryptedSecret", .blob).notNull()
                t.column("algorithm", .text).notNull().defaults(to: TOTPAlgorithm.sha1.rawValue)
                t.column("digits", .integer).notNull().defaults(to: 6)
                t.column("period", .integer).notNull().defaults(to: 30)
                t.column("icon", .text)
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        try migrator.migrate(dbWriter)
    }
}
