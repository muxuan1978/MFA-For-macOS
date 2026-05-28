import AVFoundation
import SwiftUI
import Vision

@MainActor
final class QRScanService: NSObject, ObservableObject {
    @Published var scannedValue: String?
    @Published var isScanning = false
    @Published var errorMessage: String?

    private var captureSession: AVCaptureSession?

    func startScanning() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
            errorMessage = "No camera available"
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            setupCaptureSession(device)
        } else if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted, let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) {
                        self?.setupCaptureSession(device)
                    } else {
                        self?.errorMessage = "Camera permission denied"
                    }
                }
            }
        } else {
            errorMessage = "Camera permission denied. Please enable in System Settings."
        }
    }

    func stopScanning() {
        captureSession?.stopRunning()
        isScanning = false
    }

    private func setupCaptureSession(_ device: AVCaptureDevice) {
        let session = AVCaptureSession()
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "qr.scan.queue"))
        session.addOutput(output)

        self.captureSession = session
        isScanning = true

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        return preview
    }
}

extension QRScanService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let request = VNDetectBarcodesRequest { [weak self] request, _ in
            for result in request.results as? [VNBarcodeObservation] ?? [] {
                guard let payload = result.payloadStringValue else { continue }
                Task { @MainActor in
                    self?.handleScanResult(payload)
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    @MainActor
    private func handleScanResult(_ payload: String) {
        guard scannedValue == nil else { return }
        scannedValue = payload
        stopScanning()
    }
}
