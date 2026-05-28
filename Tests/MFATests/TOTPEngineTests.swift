import XCTest
@testable import MFA

final class TOTPEngineTests: XCTestCase {

    let sha1Secret = Data("12345678901234567890".utf8)

    func testGenerateSHA1CodeAtTime59() {
        let code = TOTPEngine.generate(secret: sha1Secret, algorithm: .sha1, digits: 6, period: 30, timestamp: 59)
        XCTAssertEqual(code, "287082")
    }

    func testGenerateSHA1CodeAtTime1111111109() {
        let code = TOTPEngine.generate(secret: sha1Secret, algorithm: .sha1, digits: 6, period: 30, timestamp: 1111111109)
        XCTAssertEqual(code, "081804")
    }

    func testGenerateSHA1CodeAtTime1234567890() {
        let code = TOTPEngine.generate(secret: sha1Secret, algorithm: .sha1, digits: 6, period: 30, timestamp: 1234567890)
        XCTAssertEqual(code, "005924")
    }

    func testGenerateSHA256Code() {
        let secret = Data("12345678901234567890123456789012".utf8)
        let code = TOTPEngine.generate(secret: secret, algorithm: .sha256, digits: 6, period: 30, timestamp: 1111111109)
        // RFC 6238: 8-digit SHA256 at t=1111111109 = 68084774 → 6-digit = 084774
        XCTAssertEqual(code, "084774")
    }

    func testGenerateSHA512Code() {
        let secret = Data("1234567890123456789012345678901234567890123456789012345678901234".utf8)
        let code = TOTPEngine.generate(secret: secret, algorithm: .sha512, digits: 6, period: 30, timestamp: 1111111109)
        // RFC 6238: 8-digit SHA512 at t=1111111109 = 25091201 → 6-digit = 091201
        XCTAssertEqual(code, "091201")
    }

    func testGenerate8DigitCode() {
        // RFC 6238 Appendix B: SHA1 8-digit at t=59 = 94287082
        let code = TOTPEngine.generate(secret: sha1Secret, algorithm: .sha1, digits: 8, period: 30, timestamp: 59)
        XCTAssertEqual(code, "94287082")
    }

    func testGenerateUsesCurrentTime() {
        let code = TOTPEngine.generate(secret: sha1Secret, algorithm: .sha1, digits: 6, period: 30)
        XCTAssertEqual(code.count, 6)
        XCTAssertTrue(code.allSatisfy { $0.isNumber })
    }

    func testRemainingSeconds() {
        XCTAssertEqual(TOTPEngine.remainingSeconds(period: 30, timestamp: 45), 15)
        XCTAssertEqual(TOTPEngine.remainingSeconds(period: 30, timestamp: 30), 30)
        XCTAssertEqual(TOTPEngine.remainingSeconds(period: 60, timestamp: 90), 30)
    }
}
