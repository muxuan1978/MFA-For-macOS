import Foundation

struct ParsedOTPAuth {
    let issuer: String
    let accountName: String
    let secretBase32: String
    let algorithm: TOTPAlgorithm
    let digits: Int
    let period: Int
}

enum OTPAuthParser {
    static func parse(_ uriString: String) throws -> ParsedOTPAuth {
        guard let url = URLComponents(string: uriString),
              url.scheme == "otpauth",
              url.host == "totp"
        else {
            throw OTPAuthError.invalidURI("Must be an otpauth://totp/ URI")
        }

        let label = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let decodedLabel = label.removingPercentEncoding ?? label

        let issuer: String
        let accountName: String

        if let colonIndex = decodedLabel.firstIndex(of: ":") {
            issuer = String(decodedLabel[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            accountName = String(decodedLabel[decodedLabel.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        } else {
            accountName = decodedLabel
            issuer = ""
        }

        var params = [String: String]()
        if let queryItems = url.queryItems {
            for item in queryItems {
                params[item.name] = item.value
            }
        }

        guard let secret = params["secret"], !secret.isEmpty else {
            throw OTPAuthError.missingSecret
        }

        let finalIssuer = params["issuer"]?.removingPercentEncoding ?? issuer
        guard !finalIssuer.isEmpty else {
            throw OTPAuthError.missingIssuer
        }

        let algorithm = TOTPAlgorithm(rawValue: params["algorithm"]?.uppercased() ?? "SHA1") ?? .sha1
        let digits = Int(params["digits"] ?? "6") ?? 6
        let period = Int(params["period"] ?? "30") ?? 30

        return ParsedOTPAuth(
            issuer: finalIssuer,
            accountName: accountName,
            secretBase32: secret,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
    }

    enum OTPAuthError: Error {
        case invalidURI(String)
        case missingSecret
        case missingIssuer
    }
}
