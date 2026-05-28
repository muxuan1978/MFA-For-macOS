import AppKit
import Vision

enum ImageImportService {

    /// Detect QR code from an image file URL. Returns the payload string or nil.
    @MainActor
    static func detectQRCode(from imageURL: URL) -> String? {
        guard let image = NSImage(contentsOf: imageURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        var result: String?

        let request = VNDetectBarcodesRequest { req, _ in
            if let observation = req.results?.first as? VNBarcodeObservation,
               let payload = observation.payloadStringValue {
                result = payload
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        return result
    }

    /// Show an NSOpenPanel to pick an image file, then detect QR code.
    @MainActor
    static func pickImageAndDetect() -> String? {
        let panel = NSOpenPanel()
        panel.title = "Select QR Code Image"
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return detectQRCode(from: url)
    }
}
