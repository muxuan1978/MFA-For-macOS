import XCTest
@testable import MFA

final class GoogleAuthParserTests: XCTestCase {
    func testParseMigrationURI() throws {
        // Build protobuf manually for one TOTP account
        let secretBytes = Base32.decode("JBSWY3DPEHPK3PXP")!

        var accountBytes = Data()
        // field 1 (name): "user@example.com" (16 bytes)
        let nameData = Data("user@example.com".utf8)
        accountBytes.append(0x0A)
        accountBytes.append(UInt8(nameData.count))
        accountBytes.append(nameData)
        // field 2 (secret): raw bytes
        accountBytes.append(0x12)
        accountBytes.append(UInt8(secretBytes.count))
        accountBytes.append(secretBytes)
        // field 3 (algorithm): SHA1=1
        accountBytes.append(0x18)
        accountBytes.append(0x01)
        // field 4 (digits): SIX=1
        accountBytes.append(0x20)
        accountBytes.append(0x01)
        // field 5 (type): TOTP=2
        accountBytes.append(0x28)
        accountBytes.append(0x02)

        var payload = Data()
        // field 1 (otpParameters)
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
        XCTAssertEqual(accounts[0].algorithm, .sha1)
        XCTAssertEqual(accounts[0].digits, 6)
        XCTAssertEqual(accounts[0].type, .totp)
    }

    func testParseInvalidURIThrows() {
        XCTAssertThrowsError(try GoogleAuthParser.parse("https://example.com"))
    }

    func testParseMissingDataThrows() {
        XCTAssertThrowsError(try GoogleAuthParser.parse("otpauth-migration://offline"))
    }
}
