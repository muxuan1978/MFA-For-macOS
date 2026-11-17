import SwiftUI

struct CodeRowView: View {
    @ObservedObject var viewModel: CodeViewModel
    @State private var copied = false
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: copyCode) {
            HStack(spacing: 10) {
                IssuerAvatar(issuer: viewModel.account.issuer)
                    .overlay(alignment: .bottomTrailing) {
                        if copied {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white, Color.green)
                                .offset(x: 3, y: 3)
                        }
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.account.issuer)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .help(viewModel.account.issuer)
                    Text(viewModel.account.accountName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(viewModel.account.accountName)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(formatCode(viewModel.code))
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 132, alignment: .trailing)

                CodeCountdownView(remainingSeconds: viewModel.remainingSeconds, progress: viewModel.progress)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(copied ? Color.green.opacity(0.08) : Color.primary.opacity(isHovered ? 0.04 : 0))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                .allowsHitTesting(false)
        }
        .accessibilityLabel("Copy verification code for \(viewModel.account.issuer), \(viewModel.account.accountName)")
        .accessibilityValue(copied ? "Copied" : "\(viewModel.code), \(viewModel.remainingSeconds) seconds remaining")
        .help(copied ? "Verification code copied" : "Click to copy verification code")
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    private func formatCode(_ code: String) -> String {
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return String(code[..<mid]) + " " + String(code[mid...])
    }

    private func copyCode() {
        viewModel.copyCode()
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
