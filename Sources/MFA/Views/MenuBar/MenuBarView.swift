import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var searchText = ""

    private var filteredAccounts: [Account] {
        guard !searchText.isEmpty else { return viewModel.accounts }
        return viewModel.accounts.filter {
            $0.issuer.localizedCaseInsensitiveContains(searchText) ||
            $0.accountName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 8) {
                HStack {
                    Image("MenuBarIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("MFA Authenticator")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Button {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Search bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    TextField("Search accounts...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Account list
            if viewModel.accounts.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "key.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.quaternary)
                    Text("No accounts yet")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Button {
                        openWindow(id: "main")
                    } label: {
                        Label("Add Account", systemImage: "plus.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredAccounts) { account in
                            if let codeVM = viewModel.codeViewModels[account.id] {
                                CodeRowView(viewModel: codeVM)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .frame(minHeight: 420)
            }

            Divider()

            // Footer
            HStack {
                Button {
                    openWindow(id: "main")
                } label: {
                    Label("Manage", systemImage: "list.bullet.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("\(viewModel.accounts.count) accounts")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 12))
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 460)
        .onAppear {
            Task { await viewModel.loadAccounts() }
        }
    }
}
