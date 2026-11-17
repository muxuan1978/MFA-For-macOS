import SwiftUI

struct AccountCardView: View {
    let account: Account
    @ObservedObject var viewModel: AccountsViewModel
    @State private var copied = false
    @State private var showDeleteConfirmation = false
    @State private var isTargeted = false
    @State private var isHovered = false
    @FocusState private var focusedControl: Control?

    private enum Control: Hashable {
        case copy, delete
    }

    private var showsControls: Bool { isHovered || focusedControl != nil }

    private var cardBackground: Color {
        if copied { return Color.green.opacity(0.08) }
        if isTargeted { return Color.accentColor.opacity(0.08) }
        return Color(nsColor: .controlBackgroundColor)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: copyCurrentCode) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        IssuerAvatar(issuer: account.issuer)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.issuer)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .help(account.issuer)
                            Text(account.accountName)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(account.accountName)
                        }

                        Spacer(minLength: 48)
                    }

                    if let codeVM = viewModel.codeViewModels[account.id] {
                        AccountCardCodeView(viewModel: codeVM, copied: copied)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .copy)
            .disabled(viewModel.codeViewModels[account.id] == nil)
            .accessibilityValue(copied ? "Copied" : "")
            .accessibilityHint("Copies the code to the clipboard")
            .help(copied ? "Verification code copied" : "Click to copy verification code")

            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .opacity(showsControls ? 0.8 : 0.25)
                    .help("Drag card to reorder")
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(showsControls ? Color.red : Color.secondary)
                        .opacity(showsControls ? 0.85 : 0.4)
                        .frame(width: 22, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focused($focusedControl, equals: .delete)
                .help("Delete account")
                .accessibilityLabel("Delete \(account.issuer) account")
            }
            .padding(.top, 17)
            .padding(.trailing, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
                .shadow(color: .black.opacity(0.025), radius: 3, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted || focusedControl == .copy
                        ? Color.accentColor : Color.gray.opacity(showsControls ? 0.22 : 0.10),
                    lineWidth: isTargeted || focusedControl == .copy ? 2 : 1
                )
                .allowsHitTesting(false)
        )
        .animation(.easeOut(duration: 0.16), value: showsControls)
        .animation(.easeOut(duration: 0.16), value: isTargeted)
        .onHover { isHovered = $0 }
        .draggable(account.id.uuidString) {
            HStack(spacing: 6) {
                Image(systemName: "key.fill")
                    .font(.system(size: 12))
                Text("\(account.issuer) - \(account.accountName)")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor)))
        }
        .dropDestination(for: String.self) { items, _ in
            guard let draggedID = items.first.flatMap({ UUID(uuidString: $0) }),
                  draggedID != account.id else { return false }
            Task { try? await viewModel.moveAccount(draggedID, before: account.id) }
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { try? await viewModel.deleteAccount(account) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove \(account.issuer) - \(account.accountName)?")
        }
    }

    private func copyCurrentCode() {
        guard let codeViewModel = viewModel.codeViewModels[account.id] else { return }
        codeViewModel.copyCode()
        withAnimation(.easeInOut(duration: 0.15)) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.15)) {
                copied = false
            }
        }
    }

}

private struct AccountCardCodeView: View {
    @ObservedObject var viewModel: CodeViewModel
    let copied: Bool

    private var formattedCode: String {
        let code = viewModel.code
        let middle = code.index(code.startIndex, offsetBy: code.count / 2)
        return String(code[..<middle]) + " " + String(code[middle...])
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(formattedCode)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityLabel("Verification code, \(viewModel.code)")
            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(copied ? Color.green : Color.secondary.opacity(0.5))
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            CodeCountdownView(remainingSeconds: viewModel.remainingSeconds, progress: viewModel.progress)
        }
    }
}
