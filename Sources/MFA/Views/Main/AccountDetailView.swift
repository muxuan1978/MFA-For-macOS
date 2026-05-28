import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @ObservedObject var viewModel: AccountsViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            if let codeVM = viewModel.codeViewModels[account.id] {
                VStack(spacing: 8) {
                    Text(codeVM.code)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))

                    CountdownArc(progress: codeVM.progress, remaining: codeVM.remainingSeconds)
                        .frame(width: 80, height: 16)

                    Button("Copy Code") {
                        codeVM.copyCode()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 40)
            }

            Spacer()

            Form {
                LabeledContent("Issuer", value: account.issuer)
                LabeledContent("Account", value: account.accountName)
                LabeledContent("Algorithm", value: account.algorithm.displayName)
                LabeledContent("Digits", value: "\(account.digits)")
                LabeledContent("Period", value: "\(account.period)s")
            }
            .formStyle(.grouped)

            Spacer()

            Button("Delete Account", role: .destructive) {
                showDeleteConfirmation = true
            }
            .padding(.bottom, 20)
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { try? await viewModel.deleteAccount(account) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \(account.issuer) - \(account.accountName).")
        }
    }
}
