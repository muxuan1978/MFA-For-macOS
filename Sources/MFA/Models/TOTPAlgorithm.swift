import CryptoKit
import Foundation

enum TOTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"

    var displayName: String { rawValue }

    func hmac(key: Data, data: Data) -> Data {
        switch self {
        case .sha1:
            return Data(HMAC<Insecure.SHA1>.authenticationCode(for: data, using: SymmetricKey(data: key)))
        case .sha256:
            return Data(HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key)))
        case .sha512:
            return Data(HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: key)))
        }
    }
}
