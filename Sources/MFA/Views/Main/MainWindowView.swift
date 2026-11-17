import AppKit
import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: AccountsViewModel

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    @State private var hostWindow: NSWindow?
    @State private var pinOnTop = true

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Image("MenuBarIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
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

                Button {
                    pinOnTop.toggle()
                } label: {
                    Image(systemName: pinOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundStyle(pinOnTop ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(pinOnTop ? "Keep on top: on" : "Keep on top: off")
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
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Account list
            if viewModel.filteredAccounts.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "key.fill")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(.quaternary)
                    Text(viewModel.accounts.isEmpty ? "Your authenticator is ready" : "No accounts found")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(viewModel.accounts.isEmpty
                         ? "Add an account to see verification codes here."
                         : "Try another service or account name.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    if viewModel.accounts.isEmpty {
                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Label("Add Account", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Clear Search") {
                            viewModel.searchQuery = ""
                        }
                        .buttonStyle(.bordered)
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
        .background(WindowAccessor { window in
            hostWindow = window
            applyPinning()
        })
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
        .onChange(of: pinOnTop) { _ in applyPinning() }
    }

    private func applyPinning() {
        guard let hostWindow else { return }
        if pinOnTop {
            hostWindow.level = .floating
            hostWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            hostWindow.level = .normal
            hostWindow.collectionBehavior = []
        }
    }

    private func exportAccounts() {
        do {
            try ExportService.exportToJSON(viewModel.accounts)
        } catch {}
    }
}
