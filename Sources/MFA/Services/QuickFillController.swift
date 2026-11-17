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
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Quick Fill"
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: QuickFillView(viewModel: viewModel) { [weak self] code in
            self?.select(code: code)
        })
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

private struct QuickFillView: View {
    @ObservedObject var viewModel: AccountsViewModel
    let onSelect: (String) -> Void
    @State private var searchText = ""
    @State private var selection = 0
    @FocusState private var focused: Bool

    private var codeRows: [CodeViewModel] {
        viewModel.accounts.compactMap { account in
            guard let code = viewModel.codeViewModels[account.id] else { return nil }
            guard searchText.isEmpty || account.issuer.localizedCaseInsensitiveContains(searchText) || account.accountName.localizedCaseInsensitiveContains(searchText) else { return nil }
            return code
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search accounts", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(14)
                .focused($focused)
                .onChange(of: searchText) { _ in selection = 0 }
            Divider()
            if codeRows.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "key").font(.title2).foregroundStyle(.secondary)
                    Text("No accounts found").foregroundStyle(.secondary)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(codeRows.enumerated()), id: \.element.account.id) { index, item in
                                Button {
                                    onSelect(item.code)
                                } label: {
                                    QuickFillCodeRow(viewModel: item)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .contentShape(Rectangle())
                                    .background(index == selection ? Color.accentColor.opacity(0.16) : .clear)
                                }
                                .buttonStyle(.plain)
                                .id(index)
                            }
                        }
                    }
                    .onChange(of: selection) { newSelection in
                        withAnimation { proxy.scrollTo(newSelection, anchor: .center) }
                    }
                }
            }
            Divider()
            HStack {
                Text("↑↓ Select")
                Spacer()
                Text("↵ Confirm")
                Spacer()
                Text("Esc Close")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(10)
        }
        .frame(width: 420, height: 420)
        .focusable()
        .focused($focused)
        .background(QuickFillKeyboardMonitor(
            selection: $selection,
            count: codeRows.count,
            onConfirm: confirmSelection,
            onEscape: { NSApp.keyWindow?.orderOut(nil) }
        ))
        .onAppear { focused = true }
    }

    private func confirmSelection() {
        guard codeRows.indices.contains(selection) else { return }
        onSelect(codeRows[selection].code)
    }
}

private struct QuickFillKeyboardMonitor: NSViewRepresentable {
    @Binding var selection: Int
    let count: Int
    let onConfirm: () -> Void
    let onEscape: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.count = count
        context.coordinator.onConfirm = onConfirm
        context.coordinator.onEscape = onEscape
        context.coordinator.installIfNeeded()
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.remove()
    }

    @MainActor
    final class Coordinator {
        var selection = Binding<Int>.constant(0)
        var count = 0
        var onConfirm: () -> Void = {}
        var onEscape: () -> Void = {}
        private var monitor: Any?

        func installIfNeeded() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self,
                      let panel = NSApp.windows.first(where: { $0.title == "Quick Fill" }),
                      panel.isVisible,
                      panel.isKeyWindow else {
                    self?.remove()
                    return event
                }
                switch event.keyCode {
                case 125:
                    if count > 0 { selection.wrappedValue = min(selection.wrappedValue + 1, count - 1) }
                    return nil
                case 126:
                    if count > 0 { selection.wrappedValue = max(selection.wrappedValue - 1, 0) }
                    return nil
                case 36, 76:
                    onConfirm()
                    return nil
                case 53:
                    onEscape()
                    return nil
                default:
                    return event
                }
            }
        }

        func remove() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }
}

private struct QuickFillCodeRow: View {
    @ObservedObject var viewModel: CodeViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.account.issuer).fontWeight(.semibold)
                Text(viewModel.account.accountName).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(viewModel.code)
                .font(.system(.title3, design: .monospaced).weight(.bold))
            Text("\(viewModel.remainingSeconds)s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
