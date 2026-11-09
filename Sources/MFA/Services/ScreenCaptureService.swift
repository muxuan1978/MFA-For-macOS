import AppKit

/// Interactive screen-region capture: lets the user drag-select an area that
/// shows a QR code, then decodes it directly via Vision — no need to save the
/// image to disk first and re-open it.
@MainActor
enum ScreenCaptureService {

    /// Orders our visible titled windows off-screen (so the always-on-top Manager
    /// window does not cover the QR being captured), runs the system interactive
    /// crosshair capture, restores the windows, and returns the decoded payload.
    static func captureRegionAndDetect() -> String? {
        let restoreable = NSApp.windows.filter { $0.isVisible && $0.styleMask.contains(.titled) }
        restoreable.forEach { $0.orderOut(nil) }

        let payload = interactiveCapture()

        restoreable.forEach {
            $0.makeKeyAndOrderFront(nil)
            $0.orderFrontRegardless()
        }
        NSApp.activate(ignoringOtherApps: true)
        return payload
    }

    private static func interactiveCapture() -> String? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mfa-capture-\(Int(Date().timeIntervalSince1970)).png")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", tempURL.path]

        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        // Cancelled selection (Esc) or empty capture leaves no usable file.
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: tempURL.path),
              let fileSize = attributes[.size] as? Int,
              fileSize > 0 else {
            return nil
        }

        return ImageImportService.detectQRCode(from: tempURL)
    }
}
