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

        Window("MFA - Accounts", id: "main") {
            MainWindowView(viewModel: accountsVM)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = NSApp.keyWindow {
                            window.makeKeyAndOrderFront(nil)
                            window.orderFrontRegardless()
                        }
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 780, height: 560)
    }
}
