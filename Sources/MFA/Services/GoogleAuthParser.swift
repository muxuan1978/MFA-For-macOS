import Foundation

struct GoogleAuthAccount {
    let name: String
    let secretBase32: String
    let issuer: String
    let algorithm: TOTPAlgorithm
    let digits: Int
    let type: OTPType

    enum OTPType: Int {
        case hotp = 0
        case totp = 1
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

        guard let protobufData = Data(base64Encoded: dataParam) else {
            throw GoogleAuthError.invalidBase64
        }

        return try parseProtobuf(protobufData)
    }

    // MARK: - Protobuf Parsing

    // Google Authenticator protobuf schema (AOSP):
    // message MigrationPayload {
    //   repeated OtpParameters otp_parameters = 1;
    //   int32 version = 2;
    //   int32 batch_size = 3;
    //   int32 batch_index = 4;
    //   int32 batch_id = 5;
    // }
    // message OtpParameters {
    //   bytes secret = 1;          // raw secret bytes
    //   string name = 2;           // e.g. "Issuer:account@domain"
    //   string issuer = 3;         // issuer name
    //   Algorithm algorithm = 4;   // 0=SHA1, 1=SHA256, 2=SHA512
    //   DigitCount digits = 5;     // 0=6, 1=8
    //   OtpType type = 6;          // 0=HOTP, 1=TOTP
    //   int64 counter = 7;         // for HOTP
    // }

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

        var secretData = Data()
        var name = ""
        var issuer = ""
        var algorithm: TOTPAlgorithm = .sha1
        var digitCount = 6
        var type: GoogleAuthAccount.OTPType = .totp

        while let (fieldNumber, wireType) = reader.readTag() {
            switch (fieldNumber, wireType) {
            case (1, .lengthDelimited): // secret (bytes)
                secretData = try reader.readLengthDelimited()
            case (2, .lengthDelimited): // name (string)
                name = try reader.readString()
            case (3, .lengthDelimited): // issuer (string)
                issuer = try reader.readString()
            case (4, .varint): // algorithm: 1=SHA1, 2=SHA256, 3=SHA512
                let raw = try reader.readVarint()
                algorithm = switch raw {
                case 2: .sha256
                case 3: .sha512
                default: .sha1
                }
            case (5, .varint): // digits: 1=6, 2=8
                let raw = try reader.readVarint()
                digitCount = (raw == 2) ? 8 : 6
            case (6, .varint): // type: 1=HOTP(?), 2=TOTP
                let raw = try reader.readVarint()
                type = (raw == 1) ? .hotp : .totp
            case (7, .varint): // counter
                _ = try reader.readVarint()
            default:
                try reader.skip(wireType: wireType)
            }
        }

        guard !secretData.isEmpty else { return nil }
        let secretBase32 = Base32.encode(secretData)

        return GoogleAuthAccount(
            name: name,
            secretBase32: secretBase32,
            issuer: issuer,
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

// MARK: - Protobuf Reader

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
