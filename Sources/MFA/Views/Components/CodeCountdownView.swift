import SwiftUI

struct CodeCountdownView: View {
    let remainingSeconds: Int
    let progress: Double

    private var tint: Color {
        if remainingSeconds <= 5 { return .red }
        if remainingSeconds <= 10 { return .orange }
        return .secondary
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.12), lineWidth: 2)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(remainingSeconds)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .frame(width: 28, height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(remainingSeconds) seconds remaining")
    }
}
