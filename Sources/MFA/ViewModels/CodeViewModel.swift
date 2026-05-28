import SwiftUI

@MainActor
final class CodeViewModel: ObservableObject {
    let account: Account
    let decryptedSecret: Data

    @Published var code: String = ""
    @Published var remainingSeconds: Int = 0
    @Published var progress: Double = 1.0

    nonisolated(unsafe) private var timer: Timer?

    init(account: Account, decryptedSecret: Data) {
        self.account = account
        self.decryptedSecret = decryptedSecret
        refreshCode()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshCode()
            }
        }
    }

    private func refreshCode() {
        let now = Int64(Date().timeIntervalSince1970)
        code = TOTPEngine.generate(
            secret: decryptedSecret,
            algorithm: account.algorithm,
            digits: account.digits,
            period: account.period,
            timestamp: now
        )
        remainingSeconds = TOTPEngine.remainingSeconds(period: account.period, timestamp: now)
        progress = Double(remainingSeconds) / Double(account.period)
    }

    func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }
}
