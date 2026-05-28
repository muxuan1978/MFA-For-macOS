import Foundation

struct GoogleAuthAccount {
    let name: String
    let secretBase32: String
    let algorithm: TOTPAlgorithm
    let digits: Int
    let type: OTPType

    enum OTPType: Int {
        case unspecified = 0
        case hotp = 1
        case totp = 2
    }
}

enum GoogleAuthParser {
    static func parse(_ uriString: String) throws -> [GoogleAuthAccount] {
        guard let url = URLComponents(string: uriString),
              url.scheme == "otpauth-migration",
              url.host == "offline"
        else {
            throw GoogleAuthError.invalidURI
        }

        guard let dataParam = url.queryItems?.first(where: { $0.name == "data" })?.value else {
            throw GoogleAuthError.missingData
        }

        let decodedData = dataParam.removingPercentEncoding ?? dataParam
        guard let protobufData = Data(base64Encoded: decodedData) else {
            throw GoogleAuthError.invalidBase64
        }

        return try parseProtobuf(protobufData)
    }

    private static func parseProtobuf(_ data: Data) throws -> [GoogleAuthAccount] {
        let reader = ProtobufReader(data: data)
        var accounts = [GoogleAuthAccount]()

        while let (fieldNumber, wireType) = reader.readTag() {
            switch (fieldNumber, wireType) {
            case (1, .lengthDelimited):
                let accountData = try reader.readLengthDelimited()
                if let account = try parseAccountValue(accountData) {
                    accounts.append(account)
                }
            case (_, .varint):
                _ = try reader.readVarint()
            default:
                try reader.skip(wireType: wireType)
            }
        }
        return accounts
    }

    private static func parseAccountValue(_ data: Data) throws -> GoogleAuthAccount? {
        let reader = ProtobufReader(data: data)
        var name = ""
        var secretData = Data()
        var algorithm: TOTPAlgorithm = .sha1
        var digitCount = 6
        var type: GoogleAuthAccount.OTPType = .totp

        while let (fieldNumber, wireType) = reader.readTag() {
            switch (fieldNumber, wireType) {
            case (1, .lengthDelimited):
                name = try reader.readString()
            case (2, .lengthDelimited):
                secretData = try reader.readLengthDelimited()
            case (3, .varint):
                let raw = try reader.readVarint()
                algorithm = switch raw {
                case 2: .sha256
                case 3: .sha512
                default: .sha1
                }
            case (4, .varint):
                let raw = try reader.readVarint()
                digitCount = (raw == 2) ? 8 : 6
            case (5, .varint):
                let raw = try reader.readVarint()
                type = GoogleAuthAccount.OTPType(rawValue: Int(raw)) ?? .totp
            default:
                try reader.skip(wireType: wireType)
            }
        }

        guard !secretData.isEmpty else { return nil }
        let secretBase32 = Base32.encode(secretData)

        return GoogleAuthAccount(
            name: name,
            secretBase32: secretBase32,
            algorithm: algorithm,
            digits: digitCount,
            type: type
        )
    }

    enum GoogleAuthError: Error {
        case invalidURI
        case missingData
        case invalidBase64
        case parsingFailed
    }
}

private enum WireType: UInt8 {
    case varint = 0
    case fixed64 = 1
    case lengthDelimited = 2
    case fixed32 = 5
}

private final class ProtobufReader {
    private let data: Data
    private var offset = 0

    init(data: Data) {
        self.data = data
    }

    func readTag() -> (fieldNumber: Int, wireType: WireType)? {
        guard offset < data.count else { return nil }
        guard let tag = readVarintUnchecked() else { return nil }
        let fieldNumber = Int(tag >> 3)
        guard let wt = WireType(rawValue: UInt8(tag & 0x07)) else { return nil }
        return (fieldNumber, wt)
    }

    func readVarint() throws -> UInt64 {
        guard offset < data.count else { throw GoogleAuthParser.GoogleAuthError.parsingFailed }
        return readVarintUnchecked()!
    }

    private func readVarintUnchecked() -> UInt64? {
        var result: UInt64 = 0
        var shift = 0
        while offset < data.count {
            let byte = data[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 { return result }
            shift += 7
            if shift > 63 { return nil }
        }
        return nil
    }

    func readLengthDelimited() throws -> Data {
        let length = try Int(readVarint())
        guard offset + length <= data.count else { throw GoogleAuthParser.GoogleAuthError.parsingFailed }
        let result = data[offset..<(offset + length)]
        offset += length
        return Data(result)
    }

    func readString() throws -> String {
        let data = try readLengthDelimited()
        return String(data: data, encoding: .utf8) ?? ""
    }

    func skip(wireType: WireType) throws {
        switch wireType {
        case .varint:
            _ = try readVarint()
        case .fixed64:
            offset += 8
        case .lengthDelimited:
            let length = try Int(readVarint())
            offset += length
        case .fixed32:
            offset += 4
        }
    }
}
