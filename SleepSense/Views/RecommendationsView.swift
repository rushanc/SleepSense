import SwiftUI

struct RecommendationsView: View {
    @StateObject private var viewModel = RecommendationsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Sleep Tips")
                    .font(.title2).bold()

                if viewModel.isLoading {
                    ProgressView("Loading personalized tips...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else if viewModel.recommendations.isEmpty {
                    Text("No recommendations yet. Keep tracking your sleep to unlock insights.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(viewModel.recommendations.enumerated()), id: \.offset) { index, tip in
                        RecommendationCard(text: tip, delay: Double(index) * 0.1)
                    }
                }

                Spacer(minLength: 24)

                Text("Bedtime Routine Ideas")
                    .font(.title3).bold()

                VStack(spacing: 12) {
                    RecommendationCard(text: "Wind down with 10 minutes of reading.")
                    RecommendationCard(text: "Avoid screens 30 minutes before bed.")
                    RecommendationCard(text: "Try a short breathing exercise before sleeping.")
                }
            }
            .padding()
        }
        .navigationTitle("Recommendations")
        .onAppear {
            viewModel.loadPredictions()
        }
    }
}

struct RecommendationCard: View {
    let text: String
    var delay: Double = 0

    @State private var isVisible: Bool = false

    var body: some View {
        Text(text)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.1)))
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeOut.delay(delay)) {
                    isVisible = true
                }
            }
    }
}
