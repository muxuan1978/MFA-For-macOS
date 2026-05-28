import Foundation
import GRDB

struct Account: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var issuer: String
    var accountName: String
    var encryptedSecret: Data
    var algorithm: TOTPAlgorithm = .sha1
    var digits: Int = 6
    var period: Int = 30
    var icon: String?
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

extension Account: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "account"
}
