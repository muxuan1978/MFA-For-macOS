import CryptoKit
import Foundation

enum TOTPEngine {

    static func generate(
        secret: Data,
        algorithm: TOTPAlgorithm,
        digits: Int,
        period: Int = 30,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970)
    ) -> String {
        let counter = timestamp / Int64(period)
        let counterData = withUnsafeBytes(of: counter.bigEndian) { Data($0) }
        let hmacResult = algorithm.hmac(key: secret, data: counterData)

        let offset = Int(hmacResult[hmacResult.count - 1] & 0x0F)
        let truncated = (Int(hmacResult[offset]) & 0x7F) << 24
            | (Int(hmacResult[offset + 1]) & 0xFF) << 16
            | (Int(hmacResult[offset + 2]) & 0xFF) << 8
            | (Int(hmacResult[offset + 3]) & 0xFF)

        let modulus = Int(truncating: NSDecimalNumber(decimal: pow(10, digits)))
        let code = truncated % modulus
        return String(format: "%0\(digits)d", code)
    }

    static func remainingSeconds(period: Int = 30, timestamp: Int64 = Int64(Date().timeIntervalSince1970)) -> Int {
        return period - Int(timestamp % Int64(period))
    }
}
