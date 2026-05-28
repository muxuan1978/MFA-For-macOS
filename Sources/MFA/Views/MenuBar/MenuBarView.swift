import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MFA")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(id: "main")
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Content
            if viewModel.accounts.isEmpty {
                VStack(spacing: 12) {
                    Text("No accounts yet")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 24)
                    Button {
                        openWindow(id: "main")
                    } label: {
                        Label("Add Account", systemImage: "plus.circle")
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

            // Footer
            HStack {
                Button {
                    openWindow(id: "main")
                } label: {
                    Label("Manage", systemImage: "plus.circle")
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
}
