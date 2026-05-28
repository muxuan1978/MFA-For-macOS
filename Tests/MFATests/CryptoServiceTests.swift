import XCTest
@testable import MFA

final class CryptoServiceTests: XCTestCase {

    func testEncryptDecryptRoundTrip() throws {
        let plaintext = Data("Hello, MFA!".utf8)
        let encrypted = try CryptoService.encrypt(plaintext)
        let decrypted = try CryptoService.decrypt(encrypted)
        XCTAssertEqual(decrypted, plaintext)
    }

    func testEncryptedDataIsDifferentFromPlaintext() throws {
        let plaintext = Data("secret".utf8)
        let encrypted = try CryptoService.encrypt(plaintext)
        XCTAssertNotEqual(encrypted, plaintext)
    }

    func testDifferentEncryptionsProduceDifferentCiphertext() throws {
        let plaintext = Data("same data".utf8)
        let enc1 = try CryptoService.encrypt(plaintext)
        let enc2 = try CryptoService.encrypt(plaintext)
        XCTAssertNotEqual(enc1, enc2)
    }

    func testDecryptGarbageThrows() {
        let garbage = Data(repeating: 0xFF, count: 32)
        XCTAssertThrowsError(try CryptoService.decrypt(garbage))
    }
}
