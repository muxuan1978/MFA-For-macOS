import XCTest
@testable import MFA

@MainActor
final class AccountsViewModelTests: XCTestCase {

    func testMoveAccountBeforeTarget() async throws {
        let store = try AccountStore(inMemory: true)
        let encrypted = try CryptoService.encrypt(Data("test".utf8))

        let a1 = try await store.save(Account(issuer: "A", accountName: "1", encryptedSecret: encrypted, sortOrder: 0))
        let a2 = try await store.save(Account(issuer: "B", accountName: "2", encryptedSecret: encrypted, sortOrder: 1))
        let a3 = try await store.save(Account(issuer: "C", accountName: "3", encryptedSecret: encrypted, sortOrder: 2))

        let viewModel = AccountsViewModel(store: store)
        await viewModel.loadAccounts()
        XCTAssertEqual(viewModel.accounts.map(\.issuer), ["A", "B", "C"])

        try await viewModel.moveAccount(a3.id, before: a1.id)
        XCTAssertEqual(viewModel.accounts.map(\.issuer), ["C", "A", "B"])

        try await viewModel.moveAccount(a2.id, before: a3.id)
        XCTAssertEqual(viewModel.accounts.map(\.issuer), ["B", "C", "A"])

        let reloaded = AccountsViewModel(store: store)
        await reloaded.loadAccounts()
        XCTAssertEqual(reloaded.accounts.map(\.issuer), ["B", "C", "A"])
    }
}
