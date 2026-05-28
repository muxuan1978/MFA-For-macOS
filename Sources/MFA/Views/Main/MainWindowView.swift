import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: AccountsViewModel

    var body: some View {
        NavigationSplitView {
            AccountListView(viewModel: viewModel)
        } detail: {
            if let selectedId = viewModel.selectedAccountId,
               let account = viewModel.accounts.first(where: { $0.id == selectedId }) {
                AccountDetailView(account: account, viewModel: viewModel)
            } else {
                Text("Select an account")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.showingAddSheet = true
                } label: {
                    Label("Add Account", systemImage: "plus")
                }

                Button {
                    viewModel.showingImport = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Button {
                    exportAccounts()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search accounts")
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
        } catch {
            // User cancelled or error
        }
    }
}
