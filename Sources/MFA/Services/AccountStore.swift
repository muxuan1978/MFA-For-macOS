import Foundation
import GRDB

@MainActor
final class AccountStore: ObservableObject {
    private let dbWriter: any DatabaseWriter

    @Published var accounts: [Account] = []

    init(inMemory: Bool = false) throws {
        if inMemory {
            self.dbWriter = try DatabaseManager.openInMemory()
        } else {
            self.dbWriter = try DatabaseManager.openDatabase()
        }
    }

    func save(_ account: Account) async throws -> Account {
        var record = account
        if record.sortOrder == 0 {
            let count = try await fetchAll().count
            record.sortOrder = count
        }
        record.updatedAt = Date()
        let toSave = record
        let saved = try await dbWriter.write { db in
            return try toSave.saved(db)
        }
        await refresh()
        return saved
    }

    func delete(_ account: Account) async throws {
        _ = try await dbWriter.write { db in
            try account.delete(db)
        }
        await refresh()
    }

    func fetchAll() async throws -> [Account] {
        try await dbWriter.read { db in
            try Account.order(Column("sortOrder")).fetchAll(db)
        }
    }

    func search(query: String) async throws -> [Account] {
        try await dbWriter.read { db in
            try Account
                .filter(
                    Column("issuer").like("%\(query)%") ||
                    Column("accountName").like("%\(query)%")
                )
                .order(Column("sortOrder"))
                .fetchAll(db)
        }
    }

    func reorder(_ ids: [UUID]) async throws {
        try await dbWriter.write { db in
            for (index, id) in ids.enumerated() {
                try Account
                    .filter(Column("id") == id)
                    .updateAll(db, Column("sortOrder").set(to: index))
            }
        }
        await refresh()
    }

    func refresh() async {
        if let fetched = try? await fetchAll() {
            self.accounts = fetched
        }
    }
}
