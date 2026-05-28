import XCTest
@testable import MFA

final class OTPAuthParserTests: XCTestCase {
    func testParseBasicTotpURI() throws {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let result = try OTPAuthParser.parse(uri)
        XCTAssertEqual(result.issuer, "GitHub")
        XCTAssertEqual(result.accountName, "user@example.com")
        XCTAssertEqual(result.secretBase32, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(result.algorithm, .sha1)
        XCTAssertEqual(result.digits, 6)
        XCTAssertEqual(result.period, 30)
    }

    func testParseFullTotpURI() throws {
        let uri = "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA256&digits=8&period=60"
        let result = try OTPAuthParser.parse(uri)
        XCTAssertEqual(result.issuer, "Example")
        XCTAssertEqual(result.accountName, "alice@google.com")
        XCTAssertEqual(result.algorithm, .sha256)
        XCTAssertEqual(result.digits, 8)
        XCTAssertEqual(result.period, 60)
    }

    func testParseWithSpacesInIssuer() throws {
        let uri = "otpauth://totp/My%20Service:user@test.com?secret=AAAABBBB&issuer=My%20Service"
        let result = try OTPAuthParser.parse(uri)
        XCTAssertEqual(result.issuer, "My Service")
        XCTAssertEqual(result.accountName, "user@test.com")
    }

    func testParseWithoutIssuerParam() throws {
        let uri = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP"
        let result = try OTPAuthParser.parse(uri)
        XCTAssertEqual(result.issuer, "GitHub")
        XCTAssertEqual(result.accountName, "user@example.com")
    }

    func testParseSimpleLabel() throws {
        let uri = "otpauth://totp/user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=TestService"
        let result = try OTPAuthParser.parse(uri)
        XCTAssertEqual(result.accountName, "user@example.com")
        XCTAssertEqual(result.issuer, "TestService")
    }

    func testParseInvalidSchemeThrows() {
        XCTAssertThrowsError(try OTPAuthParser.parse("https://example.com"))
    }

    func testParseHotpThrows() {
        let uri = "otpauth://hotp/Test:test@test.com?secret=AAA&counter=1"
        XCTAssertThrowsError(try OTPAuthParser.parse(uri))
    }

    func testParseMissingSecretThrows() {
        let uri = "otpauth://totp/Test:test@test.com?issuer=Test"
        XCTAssertThrowsError(try OTPAuthParser.parse(uri))
    }
}
