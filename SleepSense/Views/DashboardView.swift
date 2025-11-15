import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var isSyncing: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            if isSyncing {
                ProgressView("Syncing last night's sleep...")
                    .padding(.top, 16)
            }

            if let score = viewModel.todayScore {
                SleepRing(score: score)
                    .frame(width: 180, height: 180)
                    .padding(.top, 32)
            } else {
                SleepRing(score: 0)
                    .frame(width: 180, height: 180)
                    .padding(.top, 32)
            }

            VStack(spacing: 8) {
                Text("Last Night")
                    .font(.headline)
                Text(viewModel.lastNightSummary ?? "Fetching last night\'s sleep...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                NavigationLink(destination: SleepAnalysisView()) {
                    Label("Analysis", systemImage: "chart.bar.xaxis")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                }

                NavigationLink(destination: RecommendationsView()) {
                    Label("Tips", systemImage: "lightbulb")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Dashboard")
        .onAppear {
            isSyncing = true
            SyncService.shared.syncLastNight { _ in
                DispatchQueue.main.async {
                    isSyncing = false
                }
            }
            viewModel.fetchLatest()
        }
    }
}
