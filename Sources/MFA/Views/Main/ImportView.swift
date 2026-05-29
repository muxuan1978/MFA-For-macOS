import SwiftUI

struct ImportView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss

    enum ImportTab: String, CaseIterable {
        case camera = "Camera"
        case image = "Image"
        case text = "Text"
    }

    @State private var selectedTab: ImportTab = .camera
    @StateObject private var scanner = QRScanService()
    @State private var textInput = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Text("Import Account")
                .font(.headline)
                .padding(.top, 16)

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(ImportTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Content
            Group {
                switch selectedTab {
                case .camera:
                    cameraTab
                case .image:
                    imageTab
                case .text:
                    textTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Error
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal, 16)
            }

            // Footer
            HStack {
                Button("Cancel") {
                    scanner.stopScanning()
                    dismiss()
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(width: 440, height: 480)
        .onDisappear {
            scanner.stopScanning()
        }
        .onChange(of: selectedTab) { tab in
            errorMessage = nil
            if tab == .camera {
                scanner.startScanning()
            } else {
                scanner.stopScanning()
            }
        }
        .onChange(of: scanner.scannedValue) { newValue in
            guard let value = newValue else { return }
            importFromURI(value)
        }
    }

    // MARK: - Camera Tab

    private var cameraTab: some View {
        VStack {
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
            }

            if scanner.isScanning {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Point camera at QR code...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            scanner.startScanning()
        }
    }

    // MARK: - Image Tab

    private var imageTab: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a QR code image file")
                .foregroundStyle(.secondary)

            Button("Choose Image...") {
                pickImageFile()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Supports PNG, JPEG, TIFF and other image formats")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .onAppear {
            scanner.stopScanning()
        }
    }

    // MARK: - Text Tab

    private var textTab: some View {
        VStack(spacing: 12) {
            Text("Paste an otpauth URI:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            TextEditor(text: $textInput)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("Supported formats:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("otpauth://totp/Issuer:Name?secret=...&issuer=...")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                Text("otpauth-migration://offline?data=...")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)

            Button("Import") {
                importFromText()
            }
            .buttonStyle(.borderedProminent)
            .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
        .onAppear {
            scanner.stopScanning()
        }
    }

    // MARK: - Actions

    private func pickImageFile() {
        if let payload = ImageImportService.pickImageAndDetect() {
            importFromURI(payload)
        } else {
            errorMessage = "No QR code found in image"
        }
    }

    private func importFromText() {
        let text = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        importFromURI(text)
    }

    private func importFromURI(_ uri: String) {
        Task {
            do {
                if uri.hasPrefix("otpauth-migration://") {
                    let count = try await viewModel.importFromGoogleAuth(uri)
                    viewModel.importMessage = "Imported \(count) account(s) from Google Authenticator"
                } else if uri.hasPrefix("otpauth://") {
                    try await viewModel.importFromOTPAuth(uri)
                    viewModel.importMessage = "Account imported successfully"
                } else {
                    errorMessage = "Unrecognized format. Must start with otpauth:// or otpauth-migration://"
                    return
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
            scanner.stopScanning()
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.showingImportResult = true
            }
        }
    }
}
