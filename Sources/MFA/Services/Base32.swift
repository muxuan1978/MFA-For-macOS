import Foundation

enum Base32 {
    static func decode(_ string: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var result = [UInt8]()
        var buffer: UInt64 = 0
        var bits = 0

        let cleaned = string.uppercased()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        for char in cleaned {
            guard let idx = alphabet.firstIndex(of: char) else { continue }
            let value = UInt64(alphabet.distance(from: alphabet.startIndex, to: idx))
            buffer = (buffer << 5) | value
            bits += 5
            if bits >= 8 {
                bits -= 8
                result.append(UInt8(truncatingIfNeeded: buffer >> bits))
            }
        }
        return Data(result)
    }

    static func encode(_ data: Data) -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var result = ""
        var buffer: UInt64 = 0
        var bits = 0

        for byte in data {
            buffer = (buffer << 8) | UInt64(byte)
            bits += 8
            while bits >= 5 {
                bits -= 5
                let index = Int((buffer >> bits) & 0x1F)
                result.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)])
            }
        }

        if bits > 0 {
            let index = Int((buffer << (5 - bits)) & 0x1F)
            result.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)])
        }
        return result
    }
}
