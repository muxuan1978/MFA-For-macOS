import SwiftUI

struct CountdownArc: View {
    let progress: Double
    let remaining: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))

                Capsule()
                    .fill(progressColor)
                    .frame(width: geo.size.width * max(progress, 0.05), height: geo.size.height)

                Text("\(remaining)")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(progressColor)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private var progressColor: Color {
        if progress > 0.5 { return .green }
        if progress > 0.2 { return .orange }
        return .red
    }
}
