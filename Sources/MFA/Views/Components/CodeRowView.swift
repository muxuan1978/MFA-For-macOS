import SwiftUI

struct CodeRowView: View {
    @ObservedObject var viewModel: CodeViewModel
    @State private var copied = false

    var body: some View {
        HStack(spacing: 12) {
            // Colored circle avatar with first letter
            Text(String(viewModel.account.issuer.prefix(1)).uppercased())
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(colorForIssuer(viewModel.account.issuer))
                .clipShape(Circle())

            // Service name + account
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.account.issuer)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(viewModel.account.accountName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // TOTP code
            Text(formatCode(viewModel.code))
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .textSelection(.enabled)

            // Circular countdown
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(viewModel.remainingSeconds)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(progressColor)
            }
            .frame(width: 30, height: 30)
            .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(copied ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
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
        .overlay(alignment: .center) {
            if copied {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                    Text("Copied!")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }

    private func formatCode(_ code: String) -> String {
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return String(code[..<mid]) + " " + String(code[mid...])
    }

    private var progressColor: Color {
        if viewModel.progress > 0.5 { return .green }
        if viewModel.progress > 0.2 { return .orange }
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
        // Deterministic color based on issuer name
        let hash = issuer.hashValue
        let r = Double((abs(hash) % 180) + 40) / 255.0
        let g = Double((abs(hash >> 8) % 180) + 40) / 255.0
        let b = Double((abs(hash >> 16) % 180) + 40) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}
