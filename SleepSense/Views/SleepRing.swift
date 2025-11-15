import SwiftUI

struct SleepRing: View {
    let score: Double // 0–100

    @State private var animatedProgress: CGFloat = 0
    @State private var isPulsing: Bool = false

    private var normalized: CGFloat {
        CGFloat(min(max(score / 100.0, 0.0), 1.0))
    }

    private var ringGradient: AngularGradient {
        AngularGradient(gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]), center: .center)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 16)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(ringGradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: animatedProgress)

            // Pulse halo for high scores
            if score >= 80 {
                Circle()
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 8)
                    .scaleEffect(isPulsing ? 1.15 : 0.95)
                    .opacity(isPulsing ? 0.0 : 1.0)
                    .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: isPulsing)
            }

            // Center label
            VStack(spacing: 4) {
                Text(String(format: "%.0f", score))
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("Sleep Score")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            animatedProgress = normalized
            if score >= 80 {
                isPulsing = true
            }
        }
        .onChange(of: score) { newValue in
            animatedProgress = CGFloat(min(max(newValue / 100.0, 0.0), 1.0))
            if newValue >= 80 {
                isPulsing = true
            } else {
                isPulsing = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sleep score")
        .accessibilityValue("\(Int(score)) out of 100")
    }
}

struct SleepRing_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SleepRing(score: 82)
                .frame(width: 200, height: 200)
                .previewDisplayName("High score – light")

            SleepRing(score: 45)
                .frame(width: 200, height: 200)
                .preferredColorScheme(.dark)
                .previewDisplayName("Low score – dark")
        }
    }
}
