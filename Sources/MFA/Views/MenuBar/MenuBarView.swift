import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("menuBarWindowHeight") private var popupHeight = 500.0
    @State private var searchText = ""
    @State private var resizeStartHeight: Double?
    @State private var hostingScreenHeight: Double?

    private var maximumPopupHeight: Double {
        let visibleHeight = hostingScreenHeight ?? Double(NSScreen.main?.visibleFrame.height ?? 880)
        return min(780, max(320, visibleHeight - 100))
    }

    private var filteredAccounts: [Account] {
        guard !searchText.isEmpty else { return viewModel.accounts }
        return viewModel.accounts.filter {
            $0.issuer.localizedCaseInsensitiveContains(searchText) ||
            $0.accountName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func showSettingsWindow() {
        openWindow(id: "settings")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSApp.activate(ignoringOtherApps: true)
            guard let window = NSApp.windows.first(where: { $0.title == "MFA - Settings" }) else { return }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
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
                        showSettingsWindow()
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
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
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
                .frame(maxHeight: .infinity)
            } else if filteredAccounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No accounts found")
                        .font(.system(size: 13, weight: .medium))
                    Text("Try another search.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Button("Clear Search") { searchText = "" }
                        .buttonStyle(.link)
                        .font(.system(size: 11))
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            resizeHandle
        }
        .frame(width: 460, height: popupHeight)
        .background(WindowAccessor { window in
            guard let visibleHeight = window.screen?.visibleFrame.height else { return }
            DispatchQueue.main.async {
                hostingScreenHeight = Double(visibleHeight)
                popupHeight = clampedHeight(popupHeight)
            }
        })
        .onAppear {
            popupHeight = clampedHeight(popupHeight)
            Task { await viewModel.loadAccounts() }
        }
    }

    private var resizeHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .frame(height: 14)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if resizeStartHeight == nil { resizeStartHeight = popupHeight }
                        guard let resizeStartHeight else { return }
                        popupHeight = clampedHeight(resizeStartHeight + Double(value.translation.height))
                    }
                    .onEnded { _ in resizeStartHeight = nil }
            )
            .accessibilityElement()
            .accessibilityLabel("Resize menu bar window")
            .accessibilityValue("\(Int(popupHeight)) points")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: popupHeight = clampedHeight(popupHeight + 40)
                case .decrement: popupHeight = clampedHeight(popupHeight - 40)
                @unknown default: break
                }
            }
            .help("Drag to adjust window height")
    }

    private func clampedHeight(_ height: Double) -> Double {
        min(max(height, 320), maximumPopupHeight)
    }
}
