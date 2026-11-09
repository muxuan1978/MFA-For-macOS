import SwiftUI

struct AccountCardView: View {
    let account: Account
    @ObservedObject var viewModel: AccountsViewModel
    @State private var copied = false
    @State private var showDeleteConfirmation = false
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: avatar + name + delete button
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .help("Drag to reorder")
                Text(String(account.issuer.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(colorForIssuer(account.issuer))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(account.issuer)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(account.accountName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // TOTP Code
            if let codeVM = viewModel.codeViewModels[account.id] {
                HStack(alignment: .center) {
                    Text(formatCode(codeVM.code))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: codeVM.progress)
                            .stroke(countdownColor(codeVM.progress), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(codeVM.remainingSeconds)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(countdownColor(codeVM.progress))
                    }
                    .frame(width: 30, height: 30)
                }

                // Copy button
                Button {
                    codeVM.copyCode()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            copied = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(copied ? "Copied!" : "Copy")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(copied ? .green : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(copied ? Color.green.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isTargeted ? Color.accentColor : Color.gray.opacity(0.12),
                              lineWidth: isTargeted ? 2 : 1)
        )
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

    private func formatCode(_ code: String) -> String {
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return String(code[..<mid]) + " " + String(code[mid...])
    }

    private func countdownColor(_ progress: Double) -> Color {
        if progress > 0.5 { return .green }
        if progress > 0.2 { return .orange }
        return .red
    }

    private func colorForIssuer(_ issuer: String) -> Color {
        let lower = issuer.lowercased()
        if lower.contains("github") { return Color(red: 0.13, green: 0.15, blue: 0.18) }
        if lower.contains("google") { return Color(red: 0.26, green: 0.52, blue: 0.96) }
        if lower.contains("aliyun") { return Color(red: 1.0, green: 0.55, blue: 0.0) }
        if lower.contains("amazon") { return Color(red: 1.0, green: 0.77, blue: 0.0) }
        if lower.contains("microsoft") { return Color(red: 0.0, green: 0.48, blue: 0.85) }
        if lower.contains("apple") { return Color(red: 0.35, green: 0.35, blue: 0.38) }
        if lower.contains("jump") { return Color(red: 0.20, green: 0.60, blue: 0.86) }
        if lower.contains("git") { return Color(red: 0.83, green: 0.33, blue: 0.12) }
        let hash = issuer.hashValue
        return Color(
            red: Double((abs(hash) % 180) + 40) / 255.0,
            green: Double((abs(hash >> 8) % 180) + 40) / 255.0,
            blue: Double((abs(hash >> 16) % 180) + 40) / 255.0
        )
    }
}
