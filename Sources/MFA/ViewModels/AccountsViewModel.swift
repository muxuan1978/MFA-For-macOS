import SwiftUI

@MainActor
final class AccountsViewModel: ObservableObject {
    private let store: AccountStore

    @Published var accounts: [Account] = []
    @Published var codeViewModels: [UUID: CodeViewModel] = [:]
    @Published var searchQuery = ""
    @Published var selectedAccountId: UUID?
    @Published var showingAddSheet = false
    @Published var showingScanner = false
    @Published var showingImport = false
    @Published var importMessage: String?
    @Published var showingImportResult = false

    var filteredAccounts: [Account] {
        guard !searchQuery.isEmpty else { return accounts }
        return accounts.filter {
            $0.issuer.localizedCaseInsensitiveContains(searchQuery) ||
            $0.accountName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    init(store: AccountStore) {
        self.store = store
    }

    func loadAccounts() async {
        await store.refresh()
        accounts = store.accounts
        rebuildCodeViewModels()
    }

    func addAccount(
        issuer: String,
        accountName: String,
        secretBase32: String,
        algorithm: TOTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30
    ) async throws {
        guard let secretData = Base32.decode(secretBase32) else {
            throw AccountsError.invalidSecret
        }
        let encrypted = try CryptoService.encrypt(secretData)
        let account = Account(
            issuer: issuer,
            accountName: accountName,
            encryptedSecret: encrypted,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
        _ = try await store.save(account)
        await loadAccounts()
    }

    func deleteAccount(_ account: Account) async throws {
        try await store.delete(account)
        await loadAccounts()
    }

    func importFromOTPAuth(_ uri: String) async throws {
        let parsed = try OTPAuthParser.parse(uri)
        try await addAccount(
            issuer: parsed.issuer,
            accountName: parsed.accountName,
            secretBase32: parsed.secretBase32,
            algorithm: parsed.algorithm,
            digits: parsed.digits,
            period: parsed.period
        )
    }

    func importFromGoogleAuth(_ uri: String) async throws -> Int {
        let googleAccounts = try GoogleAuthParser.parse(uri)
        for ga in googleAccounts {
            guard ga.type == .totp else { continue }
            try await addAccount(
                issuer: extractIssuer(from: ga.name),
                accountName: extractAccountName(from: ga.name),
                secretBase32: ga.secretBase32,
                algorithm: ga.algorithm,
                digits: ga.digits
            )
        }
        return googleAccounts.count
    }

    func reorderAccounts(_ ids: [UUID]) async throws {
        try await store.reorder(ids)
        await loadAccounts()
    }

    private func rebuildCodeViewModels() {
        var newViewModels: [UUID: CodeViewModel] = [:]
        for account in accounts {
            if let existing = codeViewModels[account.id] {
                newViewModels[account.id] = existing
            } else {
                do {
                    let secret = try CryptoService.decrypt(account.encryptedSecret)
                    newViewModels[account.id] = CodeViewModel(account: account, decryptedSecret: secret)
                } catch {
                    // Skip accounts we can't decrypt
                }
            }
        }
        codeViewModels = newViewModels
    }

    private func extractIssuer(from name: String) -> String {
        if let colonIndex = name.firstIndex(of: ":") {
            return String(name[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        }
        return name
    }

    private func extractAccountName(from name: String) -> String {
        if let colonIndex = name.firstIndex(of: ":") {
            return String(name[name.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        }
        return name
    }

    enum AccountsError: Error {
        case invalidSecret
    }
}
