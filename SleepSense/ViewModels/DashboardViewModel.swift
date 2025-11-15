import Foundation
import Combine
import HealthKit

final class DashboardViewModel: ObservableObject {
    @Published var todayScore: Double?
    @Published var lastNightSummary: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let healthStore: HealthStore
    private let sleepDataManager: SleepDataManager

    private var cancellables = Set<AnyCancellable>()

    init(healthStore: HealthStore = .shared,
         sleepDataManager: SleepDataManager = .shared) {
        self.healthStore = healthStore
        self.sleepDataManager = sleepDataManager
    }

    func fetchLatest() {
        isLoading = true
        errorMessage = nil

        healthStore.fetchLastNightSleep { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            case .success(let samples):
                guard let sample = samples.last else {
                    self.isLoading = false
                    self.todayScore = nil
                    self.lastNightSummary = "No sleep data for last night."
                    return
                }

                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                let hours = duration / 3600.0

                // Simple heuristic score from duration (placeholder until ML model is added).
                let score = min(100.0, max(0.0, (hours / 8.0) * 100.0))

                self.sleepDataManager.saveSleepEntry(from: sample,
                                                     sleepScore: score,
                                                     notes: nil) { _ in }

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.todayScore = score

                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.hour, .minute]
                    formatter.unitsStyle = .short
                    let formatted = formatter.string(from: duration) ?? String(format: "%.1f h", hours)
                    self.lastNightSummary = "Slept \(formatted) last night."
                }
            }
        }
    }
}
