import CryptoKit
import Foundation
import Security

enum KeychainService {
    private static let serviceIdentifier = "com.mfa.app.encryption-key"

    static func getOrCreateEncryptionKey() throws -> Data {
        if let existing = queryKeychain() {
            return existing
        }
        let newKey = generateRandomKey()
        try saveToKeychain(newKey)
        return newKey
    }

    private static func generateRandomKey() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0) }
    }

    private static func queryKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: "encryption-key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func saveToKeychain(_ data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: "encryption-key",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    enum KeychainError: Error {
        case saveFailed(OSStatus)
    }
}
