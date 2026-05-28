import XCTest
@testable import MFA

final class GoogleAuthParserTests: XCTestCase {
    func testParseMigrationURI() throws {
        // Build protobuf using correct Google Auth schema:
        // OtpParameters: secret=1, name=2, issuer=3, algorithm=4, digits=5, type=6
        let secretBytes = Base32.decode("JBSWY3DPEHPK3PXP")!

        var accountBytes = Data()
        // field 1 (secret): raw bytes — tag = (1 << 3) | 2 = 0x0A
        accountBytes.append(0x0A)
        accountBytes.append(UInt8(secretBytes.count))
        accountBytes.append(secretBytes)
        // field 2 (name): "user@example.com" — tag = (2 << 3) | 2 = 0x12
        let nameData = Data("user@example.com".utf8)
        accountBytes.append(0x12)
        accountBytes.append(UInt8(nameData.count))
        accountBytes.append(nameData)
        // field 3 (issuer): "TestIssuer" — tag = (3 << 3) | 2 = 0x1A
        let issuerData = Data("TestIssuer".utf8)
        accountBytes.append(0x1A)
        accountBytes.append(UInt8(issuerData.count))
        accountBytes.append(issuerData)
        // field 4 (algorithm): SHA1=0 — tag = (4 << 3) | 0 = 0x20
        accountBytes.append(0x20)
        accountBytes.append(0x00)
        // field 5 (digits): 6=0 — tag = (5 << 3) | 0 = 0x28
        accountBytes.append(0x28)
        accountBytes.append(0x00)
        // field 6 (type): TOTP=1 — tag = (6 << 3) | 0 = 0x30
        accountBytes.append(0x30)
        accountBytes.append(0x01)

        var payload = Data()
        // MigrationPayload field 1 (otpParameters)
        payload.append(0x0A)
        payload.append(UInt8(accountBytes.count))
        payload.append(accountBytes)
        // field 2 (version): 1
        payload.append(0x10)
        payload.append(0x01)

        let base64Data = payload.base64EncodedString()
        let uri = "otpauth-migration://offline?data=\(base64Data)"

        let accounts = try GoogleAuthParser.parse(uri)
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].name, "user@example.com")
        XCTAssertEqual(accounts[0].secretBase32, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(accounts[0].issuer, "TestIssuer")
        XCTAssertEqual(accounts[0].algorithm, .sha1)
        XCTAssertEqual(accounts[0].digits, 6)
        XCTAssertEqual(accounts[0].type, .totp)
    }

    func testParseSHA256Account() throws {
        let secretBytes = Base32.decode("JBSWY3DPEHPK3PXP")!

        var accountBytes = Data()
        // field 1 (secret)
        accountBytes.append(0x0A)
        accountBytes.append(UInt8(secretBytes.count))
        accountBytes.append(secretBytes)
        // field 2 (name)
        let nameData = Data("test@github.com".utf8)
        accountBytes.append(0x12)
        accountBytes.append(UInt8(nameData.count))
        accountBytes.append(nameData)
        // field 4 (algorithm): SHA256=1
        accountBytes.append(0x20)
        accountBytes.append(0x01)
        // field 5 (digits): 8=1
        accountBytes.append(0x28)
        accountBytes.append(0x01)
        // field 6 (type): TOTP=1
        accountBytes.append(0x30)
        accountBytes.append(0x01)

        var payload = Data()
        payload.append(0x0A)
        payload.append(UInt8(accountBytes.count))
        payload.append(accountBytes)

        let base64Data = payload.base64EncodedString()
        let uri = "otpauth-migration://offline?data=\(base64Data)"

        let accounts = try GoogleAuthParser.parse(uri)
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].algorithm, .sha256)
        XCTAssertEqual(accounts[0].digits, 8)
    }

    func testParseInvalidURIThrows() {
        XCTAssertThrowsError(try GoogleAuthParser.parse("https://example.com"))
    }

    func testParseMissingDataThrows() {
        XCTAssertThrowsError(try GoogleAuthParser.parse("otpauth-migration://offline"))
    }
}
