import Foundation
import Combine
import HealthKit

final class SleepAnalysisViewModel: ObservableObject {
    @Published var weeklyStats: [Date: TimeInterval] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var entries: [SleepEntry] = []

    private let healthStore: HealthStore
    private let sleepDataManager: SleepDataManager

    private var cancellables = Set<AnyCancellable>()

    init(healthStore: HealthStore = .shared,
         sleepDataManager: SleepDataManager = .shared) {
        self.healthStore = healthStore
        self.sleepDataManager = sleepDataManager
    }

    func fetchWeek() {
        isLoading = true
        errorMessage = nil

        healthStore.fetchWeeklySleepAggregatedByDay { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            case .success(let stats):
                self.weeklyStats = stats
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)

                self.sleepDataManager.fetchEntries(from: startDate, to: endDate) { [weak self] fetchResult in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        self.isLoading = false

                        switch fetchResult {
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                        case .success(let entries):
                            self.entries = entries
                        }
                    }
                }
            }
        }
    }

    func updateNotes(for id: UUID, notes: String?) {
        sleepDataManager.updateNotes(for: id, notes: notes) { [weak self] _ in
            guard let self = self else { return }
            // Refresh current week entries after updating notes
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)
            self.sleepDataManager.fetchEntries(from: startDate, to: endDate) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if case let .success(entries) = result {
                        self.entries = entries
                    }
                }
            }
        }
    }
}
