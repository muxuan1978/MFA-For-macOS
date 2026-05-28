import SwiftUI

@main
struct MFAApp: App {
    @StateObject private var store: AccountStore
    @StateObject private var accountsVM: AccountsViewModel

    init() {
        let store = try! AccountStore()
        let vm = AccountsViewModel(store: store)
        _store = StateObject(wrappedValue: store)
        _accountsVM = StateObject(wrappedValue: vm)
    }

    var body: some Scene {
        MenuBarExtra("MFA", systemImage: "lock.shield") {
            MenuBarView(viewModel: accountsVM)
        }
        .menuBarExtraStyle(.window)

        WindowGroup(id: "main") {
            MainWindowView(viewModel: accountsVM)
                .onReceive(NotificationCenter.default.publisher(for: .openMainWindow)) { _ in
                    openMainWindow()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 700, height: 500)
    }

    private func openMainWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
