import SwiftUI

struct CodeRowView: View {
    @ObservedObject var viewModel: CodeViewModel
    @State private var copied = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForIssuer(viewModel.account.issuer))
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.account.issuer)
                    .font(.headline)
                    .lineLimit(1)
                Text(viewModel.account.accountName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.code)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .textSelection(.enabled)

                CountdownArc(progress: viewModel.progress, remaining: viewModel.remainingSeconds)
                    .frame(width: 40, height: 12)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.copyCode()
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        }
        .overlay {
            if copied {
                Text("Copied!")
                    .font(.caption)
                    .padding(4)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .transition(.opacity)
            }
        }
    }

    private func iconForIssuer(_ issuer: String) -> String {
        let lower = issuer.lowercased()
        if lower.contains("github") { return "lock.shield" }
        if lower.contains("google") { return "globe" }
        if lower.contains("microsoft") { return "lock.shield" }
        if lower.contains("apple") { return "apple.logo" }
        if lower.contains("amazon") { return "box.trianglebadge.fill" }
        return "key.fill"
    }
}
