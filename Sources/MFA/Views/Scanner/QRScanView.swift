import AVFoundation
import SwiftUI

struct QRScanView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @StateObject private var scanner = QRScanService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Scan QR Code")
                .font(.headline)

            if let error = scanner.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                CameraPreviewRepresentable(scanner: scanner)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Button("Cancel") {
                    scanner.stopScanning()
                    dismiss()
                }
                Spacer()
                if scanner.isScanning {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 450)
        .onAppear {
            scanner.startScanning()
        }
        .onChange(of: scanner.scannedValue) { newValue in
            guard let value = newValue else { return }
            handleScannedValue(value)
        }
        .onDisappear {
            scanner.stopScanning()
        }
    }

    private func handleScannedValue(_ value: String) {
        Task {
            do {
                if value.hasPrefix("otpauth-migration://") {
                    let count = try await viewModel.importFromGoogleAuth(value)
                    viewModel.importMessage = "Imported \(count) account(s) from Google Authenticator"
                } else if value.hasPrefix("otpauth://") {
                    try await viewModel.importFromOTPAuth(value)
                    viewModel.importMessage = "Account imported successfully"
                } else {
                    viewModel.importMessage = "Unrecognized QR code format"
                }
            } catch {
                viewModel.importMessage = "Import failed: \(error.localizedDescription)"
            }
            viewModel.showingScanner = false
            viewModel.showingImportResult = true
        }
    }
}

struct CameraPreviewRepresentable: NSViewRepresentable {
    @ObservedObject var scanner: QRScanService

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        if let previewLayer = scanner.makePreviewLayer() {
            view.layer?.addSublayer(previewLayer)
            DispatchQueue.main.async {
                previewLayer.frame = view.bounds
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = nsView.layer?.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = nsView.bounds
        }
    }
}
