import AppKit
import Carbon
import Combine
import SwiftUI

@MainActor
final class QuickFillController: ObservableObject {
    @Published var autoPaste = UserDefaults.standard.object(forKey: "quickFillAutoPaste") as? Bool ?? true {
        didSet { UserDefaults.standard.set(autoPaste, forKey: "quickFillAutoPaste") }
    }
    @Published var shortcut: QuickFillShortcut = QuickFillShortcut(rawValue: UserDefaults.standard.integer(forKey: "quickFillShortcut")) ?? .controlOptionSpace {
        didSet {
            guard registerShortcut() else {
                shortcutRegistrationFailed = true
                shortcut = oldValue
                return
            }
            shortcutRegistrationFailed = false
            UserDefaults.standard.set(shortcut.rawValue, forKey: "quickFillShortcut")
        }
    }
    @Published private(set) var shortcutRegistrationFailed = false
    @Published private(set) var hasKeyboardControlPermission = CGPreflightPostEventAccess()
    @Published private(set) var permissionSettingsOpenFailed = false
    @Published private(set) var permissionRequestMessage: String?

    private let viewModel: AccountsViewModel
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var panel: NSPanel?
    private var previousApp: NSRunningApplication?

    init(viewModel: AccountsViewModel) {
        self.viewModel = viewModel
        installEventHandler()
        shortcutRegistrationFailed = !registerShortcut()
    }

    func requestKeyboardControlPermission() {
        let granted = CGRequestPostEventAccess()
        hasKeyboardControlPermission = granted || CGPreflightPostEventAccess()
        permissionRequestMessage = hasKeyboardControlPermission
            ? "Keyboard control permission is granted."
            : "Permission is still not granted. Approve the macOS prompt, then quit and reopen MFA."
        refreshKeyboardControlPermission(after: 1)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            permissionSettingsOpenFailed = !NSWorkspace.shared.open(url)
        } else {
            permissionSettingsOpenFailed = true
        }
    }

    func refreshKeyboardControlPermission(after delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.hasKeyboardControlPermission = CGPreflightPostEventAccess()
            if self.hasKeyboardControlPermission, self.permissionRequestMessage != nil {
                self.permissionRequestMessage = "Keyboard control permission is granted."
            }
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: EventHandlerProcPtr = { _, event, userData in
            var identifier = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard status == noErr, identifier.id == 1, let userData else { return noErr }
            let controller = Unmanaged<QuickFillController>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { MainActor.assumeIsolated { controller.show() } }
            return noErr
        }

        guard InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, context, &eventHandler) == noErr else { return }
    }

    @discardableResult
    private func registerShortcut() -> Bool {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        var identifier = EventHotKeyID(signature: OSType(0x4D464151), id: 1)
        let registered = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, identifier, GetApplicationEventTarget(), 0, &hotKey)
        if registered != noErr { hotKey = nil }
        return registered == noErr
    }

    private func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        Task { await viewModel.loadAccounts() }
        let panel = self.panel ?? makePanel()
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makePanel() -> NSPanel {
        let frame = NSRect(x: 0, y: 0, width: 532, height: 440)
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Quick Fill"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        let hostingView = NSHostingView(rootView: QuickFillView(viewModel: viewModel) { [weak self] code in
            self?.select(code: code)
        })
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        panel.setFrame(frame, display: false)
        self.panel = panel
        return panel
    }

    private func select(code: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        panel?.orderOut(nil)

        guard autoPaste, CGPreflightPostEventAccess(), let previousApp else {
            previousApp?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return
        }

        activateAndPaste(into: previousApp, attemptsRemaining: 10)
    }

    private func activateAndPaste(into app: NSRunningApplication, attemptsRemaining: Int) {
        app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier else {
            guard attemptsRemaining > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.activateAndPaste(into: app, attemptsRemaining: attemptsRemaining - 1)
            }
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

enum QuickFillShortcut: Int, CaseIterable, Identifiable, Hashable {
    case controlOptionSpace
    case commandShiftK
    case controlShiftM

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .controlOptionSpace: return "⌃⌥ Space"
        case .commandShiftK: return "⌘⇧ K"
        case .controlShiftM: return "⌃⇧ M"
        }
    }
    var keyCode: UInt32 {
        switch self {
        case .controlOptionSpace: return UInt32(kVK_Space)
        case .commandShiftK: return UInt32(kVK_ANSI_K)
        case .controlShiftM: return UInt32(kVK_ANSI_M)
        }
    }
    var modifiers: UInt32 {
        switch self {
        case .controlOptionSpace: return UInt32(controlKey | optionKey)
        case .commandShiftK: return UInt32(cmdKey | shiftKey)
        case .controlShiftM: return UInt32(controlKey | shiftKey)
        }
    }
}
