import SwiftUI

struct IssuerAvatar: View {
    let issuer: String

    private var normalizedIssuer: String {
        issuer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var tint: Color {
        let name = normalizedIssuer
        if name.contains("github") { return Color(red: 0.25, green: 0.29, blue: 0.36) }
        if name.contains("google") { return Color(red: 0.20, green: 0.40, blue: 0.78) }
        if name.contains("aliyun") || name.contains("amazon") {
            return Color(red: 0.68, green: 0.34, blue: 0.12)
        }
        if name.contains("microsoft") { return Color(red: 0.12, green: 0.43, blue: 0.66) }
        if name.contains("apple") { return Color(red: 0.38, green: 0.38, blue: 0.42) }

        // Stable across launches; Swift's hashValue is randomized per process.
        let hash = name.utf8.reduce(UInt64(14695981039346656037)) { value, byte in
            (value ^ UInt64(byte)) &* 1099511628211
        }
        let palette: [Color] = [
            Color(red: 0.35, green: 0.38, blue: 0.70),
            Color(red: 0.15, green: 0.45, blue: 0.43),
            Color(red: 0.52, green: 0.33, blue: 0.62),
            Color(red: 0.22, green: 0.43, blue: 0.64),
            Color(red: 0.62, green: 0.34, blue: 0.35),
        ]
        return palette[Int(hash % UInt64(palette.count))]
    }

    var body: some View {
        Text(normalizedIssuer.first.map { String($0).uppercased() } ?? "?")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}
