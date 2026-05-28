import XCTest
@testable import MFA

final class AccountStoreTests: XCTestCase {
    var store: AccountStore!

    override func setUp() async throws {
        store = try await AccountStore(inMemory: true)
    }

    func testCreateAndFetchAccount() async throws {
        let secret = Data("JBSWY3DPEHPK3PXP".utf8)
        let encrypted = try CryptoService.encrypt(secret)

        let account = Account(
            issuer: "GitHub",
            accountName: "user@example.com",
            encryptedSecret: encrypted
        )

        let saved = try await store.save(account)
        let fetched = try await store.fetchAll()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].id, saved.id)
        XCTAssertEqual(fetched[0].issuer, "GitHub")
        XCTAssertEqual(fetched[0].accountName, "user@example.com")
    }

    func testDeleteAccount() async throws {
        let encrypted = try CryptoService.encrypt(Data("test".utf8))
        let account = Account(issuer: "Test", accountName: "test", encryptedSecret: encrypted)

        let saved = try await store.save(account)
        try await store.delete(saved)
        let fetched = try await store.fetchAll()
        XCTAssertEqual(fetched.count, 0)
    }

    func testUpdateAccount() async throws {
        let encrypted = try CryptoService.encrypt(Data("test".utf8))
        var account = Account(issuer: "Test", accountName: "test", encryptedSecret: encrypted)

        account = try await store.save(account)
        account.issuer = "Updated"
        _ = try await store.save(account)

        let fetched = try await store.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].issuer, "Updated")
    }

    func testFetchByIssuer() async throws {
        let encrypted = try CryptoService.encrypt(Data("test".utf8))

        _ = try await store.save(Account(issuer: "GitHub", accountName: "a@b.com", encryptedSecret: encrypted))
        _ = try await store.save(Account(issuer: "Google", accountName: "c@d.com", encryptedSecret: encrypted))
        _ = try await store.save(Account(issuer: "GitHub", accountName: "e@f.com", encryptedSecret: encrypted))

        let all = try await store.fetchAll()
        XCTAssertEqual(all.count, 3)

        let filtered = try await store.search(query: "GitHub")
        XCTAssertEqual(filtered.count, 2)
    }

    func testReorder() async throws {
        let encrypted = try CryptoService.encrypt(Data("test".utf8))
        let a1 = try await store.save(Account(issuer: "A", accountName: "1", encryptedSecret: encrypted, sortOrder: 0))
        let a2 = try await store.save(Account(issuer: "B", accountName: "2", encryptedSecret: encrypted, sortOrder: 1))
        let a3 = try await store.save(Account(issuer: "C", accountName: "3", encryptedSecret: encrypted, sortOrder: 2))

        try await store.reorder([a3.id, a1.id, a2.id])

        let fetched = try await store.fetchAll()
        XCTAssertEqual(fetched[0].issuer, "C")
        XCTAssertEqual(fetched[1].issuer, "A")
        XCTAssertEqual(fetched[2].issuer, "B")
    }
}
