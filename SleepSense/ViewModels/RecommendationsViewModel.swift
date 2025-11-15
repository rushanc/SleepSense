import Foundation
import Combine

final class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [String] = []
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

    func loadPredictions() {
        isLoading = true
        errorMessage = nil

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)

        sleepDataManager.fetchEntries(from: startDate, to: endDate) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            case .success(let entries):
                self.healthStore.fetchWeeklySleepAggregatedByDay { [weak self] statsResult in
                    guard let self = self else { return }

                    switch statsResult {
                    case .failure(let error):
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                    case .success(let stats):
                        let suggestions = self.suggestionsFromML(entries: entries, stats: stats)
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.recommendations = suggestions
                        }
                    }
                }
            }
        }
    }

    // Placeholder for ML-based suggestions. Integrate Core ML here later.
    func suggestionsFromML(entries: [SleepEntry],
                           stats: [Date: TimeInterval]) -> [String] {
        guard !entries.isEmpty else {
            return ["Not enough data yet. Keep wearing your device at night."]
        }

        let averageDuration = stats.values.reduce(0, +) / Double(stats.count)
        let averageHours = averageDuration / 3600.0

        var result: [String] = []

        if averageHours < 7 {
            result.append("Aim for at least 7 hours of sleep on most nights.")
        } else {
            result.append("Your total sleep duration looks good. Focus on consistency.")
        }

        if entries.last?.sleepScore ?? 0 < 70 {
            result.append("Consider a consistent bedtime and reducing screen time before bed.")
        }

        return result
    }
}
