import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: AccountsViewModel

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text("MFA Authenticator")
                    .font(.system(size: 15, weight: .bold))

                Spacer()

                Button {
                    viewModel.showingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    viewModel.showingImport = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    exportAccounts()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField("Search accounts...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Card grid
            if viewModel.filteredAccounts.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "key.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.quaternary)
                    Text(viewModel.accounts.isEmpty ? "No accounts yet" : "No matching accounts")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    if viewModel.accounts.isEmpty {
                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Label("Add Account", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredAccounts) { account in
                            AccountCardView(account: account, viewModel: viewModel)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 680, minHeight: 500)
        .sheet(isPresented: $viewModel.showingAddSheet) {
            AccountEditView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingImport) {
            ImportView(viewModel: viewModel)
        }
        .alert("Import Result", isPresented: $viewModel.showingImportResult, presenting: viewModel.importMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
        .onAppear {
            Task { await viewModel.loadAccounts() }
        }
    }

    private func exportAccounts() {
        do {
            try ExportService.exportToJSON(viewModel.accounts)
        } catch {}
    }
}
