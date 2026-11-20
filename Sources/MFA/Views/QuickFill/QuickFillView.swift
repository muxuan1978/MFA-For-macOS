import SwiftUI

private struct QuickFillKeyboardMonitor: NSViewRepresentable {
    @Binding var selection: Int
    let count: Int
    let onConfirm: () -> Void
    let onEscape: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.view = nsView
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
        weak var view: NSView?
        var selection = Binding<Int>.constant(0)
        var count = 0
        var onConfirm: () -> Void = {}
        var onEscape: () -> Void = {}
        private var monitor: Any?

        func installIfNeeded() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self,
                      let panel = view?.window,
                      panel.isVisible,
                      panel.isKeyWindow else {
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

struct QuickFillView: View {
    @ObservedObject var viewModel: AccountsViewModel
    let onSelect: (String) -> Void
    @State private var query = ""
    @State private var selection = 0
    @FocusState private var searchFocused: Bool

    private var results: [CodeViewModel] {
        viewModel.accounts.compactMap { account in
            guard query.isEmpty || account.issuer.localizedCaseInsensitiveContains(query)
                || account.accountName.localizedCaseInsensitiveContains(query) else { return nil }
            return viewModel.codeViewModels[account.id]
        }
    }

    var body: some View {
        let rows = results
        VStack(spacing: 0) {
            searchBar
            Divider()
            if rows.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(Array(rows.enumerated()), id: \.element.account.id) { index, item in
                                Button { onSelect(item.code) } label: {
                                    QuickFillRow(item: item, selected: index == selection)
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(index == selection ? .isSelected : [])
                                .id(index)
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: selection) { proxy.scrollTo($0) }
                }
            }
            Divider()
            HStack(spacing: 14) {
                Label("Quick Fill", systemImage: "key.fill")
                    .fontWeight(.medium)
                Spacer()
                keyHint("↑↓", "Select")
                keyHint("↵", "Confirm")
                keyHint("esc", "Close")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .frame(height: 38)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .ignoresSafeArea()
        .background(QuickFillKeyboardMonitor(
            selection: $selection,
            count: rows.count,
            onConfirm: {
                guard rows.indices.contains(selection) else { return }
                onSelect(rows[selection].code)
            },
            onEscape: { NSApp.keyWindow?.orderOut(nil) }
        ))
        .onChange(of: query) { _ in selection = 0 }
        .onChange(of: rows.count) { selection = min(selection, max(0, $0 - 1)) }
        .onAppear { searchFocused = true }
    }

    private var searchBar: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
                .accessibilityHidden(true)
            TextField("Search accounts", text: $query)
                .font(.system(size: 20))
                .textFieldStyle(.plain)
                .focused($searchFocused)
            if !query.isEmpty {
                Button {
                    query = ""
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 68)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: query.isEmpty ? "key" : "magnifyingglass")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(query.isEmpty ? "No accounts available" : "No matching accounts")
                .font(.headline)
            Text(query.isEmpty ? "Add an account in MFA to get started." : "Try another issuer or account name.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func keyHint(_ key: String, _ action: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .padding(.horizontal, 4)
                .frame(minWidth: 18, minHeight: 16)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            Text(action)
        }
    }
}

private struct QuickFillRow: View {
    @ObservedObject var item: CodeViewModel
    let selected: Bool
    @State private var hovered = false

    var body: some View {
        let issuer = item.account.issuer
        let name = item.account.accountName
        let shape = RoundedRectangle(cornerRadius: 11, style: .continuous)
        HStack(spacing: 12) {
            IssuerAvatar(issuer: issuer.isEmpty ? name : issuer)
            VStack(alignment: .leading, spacing: 3) {
                Text(issuer.isEmpty ? name : issuer)
                    .font(.system(size: 14, weight: .semibold))
                if !issuer.isEmpty && !name.isEmpty {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .truncationMode(.middle)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.formattedCode)
                .font(.system(size: 21, weight: .medium, design: .monospaced))
                .fixedSize()
            CodeCountdownView(remainingSeconds: item.remainingSeconds, progress: item.progress)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(selected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(hovered ? 0.05 : 0), in: shape)
        .overlay { shape.strokeBorder(selected ? Color.accentColor.opacity(0.35) : .clear) }
        .contentShape(shape)
        .onHover { hovered = $0 }
    }
}
