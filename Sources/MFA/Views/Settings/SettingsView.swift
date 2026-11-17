import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var quickFill: QuickFillController
    @Environment(\.scenePhase) private var scenePhase
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !newValue
                    }
                }

            Section("Quick Fill") {
                HStack {
                    Text("Keyboard control permission")
                    Spacer()
                    Label(
                        quickFill.hasKeyboardControlPermission ? "Allowed" : "Not allowed",
                        systemImage: quickFill.hasKeyboardControlPermission ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    )
                    .foregroundStyle(quickFill.hasKeyboardControlPermission ? .green : .orange)
                }
                HStack {
                    Text("Global shortcut")
                    Spacer()
                    Picker("", selection: $quickFill.shortcut) {
                        ForEach(QuickFillShortcut.allCases) { shortcut in
                            Text(shortcut.title).tag(shortcut)
                        }
                    }
                    .labelsHidden()
                }
                if quickFill.shortcutRegistrationFailed {
                    Text("That shortcut is already in use. The previous shortcut remains active.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Toggle("Paste code into previous app", isOn: $quickFill.autoPaste)
                Text("Select an account to copy its current code. Allow the macOS prompt for posting keyboard events. The Accessibility switch is a separate permission.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Request Keyboard Control Permission") {
                    quickFill.requestKeyboardControlPermission()
                }
                if let message = quickFill.permissionRequestMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(quickFill.hasKeyboardControlPermission ? .green : .orange)
                }
                Button("Open Accessibility Settings") {
                    quickFill.openAccessibilitySettings()
                }
                if quickFill.permissionSettingsOpenFailed {
                    Text("Open System Settings → Privacy & Security → Accessibility and enable MFA.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear { quickFill.refreshKeyboardControlPermission() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { quickFill.refreshKeyboardControlPermission() }
        }
    }
}
