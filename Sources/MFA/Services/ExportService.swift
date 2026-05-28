import AppKit
import CoreImage.CIFilterBuiltins
import Foundation
import UniformTypeIdentifiers

struct ExportAccount: Codable {
    let issuer: String
    let accountName: String
    let secretBase32: String
    let algorithm: String
    let digits: Int
    let period: Int
}

enum ExportService {
    @MainActor
    static func exportToJSON(_ accounts: [Account]) throws {
        var exportAccounts: [ExportAccount] = []
        for account in accounts {
            let secret = try CryptoService.decrypt(account.encryptedSecret)
            exportAccounts.append(ExportAccount(
                issuer: account.issuer,
                accountName: account.accountName,
                secretBase32: Base32.encode(secret),
                algorithm: account.algorithm.rawValue,
                digits: account.digits,
                period: account.period
            ))
        }

        let data = try JSONEncoder().encode(exportAccounts)
        let dataWithFormatting = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(
            withJSONObject: dataWithFormatting,
            options: [.prettyPrinted, .sortedKeys]
        )

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "mfa-accounts.json"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK else {
            return
        }

        guard let url = panel.url else { return }
        try prettyData.write(to: url)
    }

    @MainActor
    static func generateQRCode(for account: Account) throws -> NSImage {
        let secret = try CryptoService.decrypt(account.encryptedSecret)
        let secretBase32 = Base32.encode(secret)

        let issuerEncoded = account.issuer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? account.issuer
        let nameEncoded = account.accountName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? account.accountName

        let uri = "otpauth://totp/\(issuerEncoded):\(nameEncoded)?secret=\(secretBase32)&issuer=\(issuerEncoded)&algorithm=\(account.algorithm.rawValue)&digits=\(account.digits)&period=\(account.period)"

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(uri.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            throw ExportError.qrGenerationFailed
        }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    enum ExportError: Error {
        case qrGenerationFailed
    }
}
