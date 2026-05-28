import CryptoKit
import Foundation

enum CryptoService {
    private static let nonceLength = 12

    static func encrypt(_ plaintext: Data) throws -> Data {
        let key = try KeychainService.getOrCreateEncryptionKey()
        let symmetricKey = SymmetricKey(data: key)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(plaintext, using: symmetricKey, nonce: nonce)
        return sealed.nonce + sealed.ciphertext + sealed.tag
    }

    static func decrypt(_ combined: Data) throws -> Data {
        guard combined.count > nonceLength + 16 else {
            throw CryptoError.invalidData
        }
        let key = try KeychainService.getOrCreateEncryptionKey()
        let symmetricKey = SymmetricKey(data: key)

        let nonce = combined.prefix(nonceLength)
        let tagStart = combined.count - 16
        let ciphertext = combined[nonceLength..<tagStart]
        let tag = combined[tagStart...]

        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: Data(ciphertext),
            tag: Data(tag)
        )
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }

    enum CryptoError: Error {
        case invalidData
    }
}
