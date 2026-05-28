import SwiftUI

struct AccountEditView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var issuer = ""
    @State private var accountName = ""
    @State private var secretKey = ""
    @State private var algorithm: TOTPAlgorithm = .sha1
    @State private var digits = 6
    @State private var period = 30
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Text("Add Account")
                .font(.headline)
                .padding()

            Form {
                TextField("Issuer", text: $issuer)
                TextField("Account Name", text: $accountName)
                SecureField("Secret Key (Base32)", text: $secretKey)

                Picker("Algorithm", selection: $algorithm) {
                    ForEach(TOTPAlgorithm.allCases, id: \.self) { algo in
                        Text(algo.displayName).tag(algo)
                    }
                }

                Picker("Digits", selection: $digits) {
                    Text("6").tag(6)
                    Text("8").tag(8)
                }

                Picker("Period", selection: $period) {
                    Text("30 seconds").tag(30)
                    Text("60 seconds").tag(60)
                }
            }
            .formStyle(.grouped)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add") {
                    addAccount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(issuer.isEmpty || accountName.isEmpty || secretKey.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 380)
    }

    private func addAccount() {
        let cleanSecret = secretKey.replacingOccurrences(of: " ", with: "").uppercased()
        guard Base32.decode(cleanSecret) != nil else {
            errorMessage = "Invalid Base32 secret key"
            return
        }
        Task {
            do {
                try await viewModel.addAccount(
                    issuer: issuer,
                    accountName: accountName,
                    secretBase32: cleanSecret,
                    algorithm: algorithm,
                    digits: digits,
                    period: period
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
