import SwiftUI

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
}

struct MenuBarView: View {
    @ObservedObject var viewModel: AccountsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("MFA")
                    .font(.headline)
                Spacer()
                Button {
                    openMainWindow()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if viewModel.accounts.isEmpty {
                VStack(spacing: 8) {
                    Text("No accounts")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                    Button("Add Account") {
                        openMainWindow()
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.accounts) { account in
                            if let codeVM = viewModel.codeViewModels[account.id] {
                                CodeRowView(viewModel: codeVM)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            Divider()

            HStack {
                Button {
                    openMainWindow()
                } label: {
                    Image(systemName: "plus.circle")
                    Text("Manage")
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        .onAppear {
            Task { await viewModel.loadAccounts() }
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
    }
}
