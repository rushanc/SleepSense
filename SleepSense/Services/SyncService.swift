import Foundation

final class SyncService {
    static let shared = SyncService()

    private let healthStore: HealthStore
    private let sleepDataManager: SleepDataManager

    private init(healthStore: HealthStore = .shared,
                 sleepDataManager: SleepDataManager = .shared) {
        self.healthStore = healthStore
        self.sleepDataManager = sleepDataManager
    }

    func syncLastNight(completion: ((Result<Void, Error>) -> Void)? = nil) {
        healthStore.fetchLastNightSleep { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let samples):
                let group = DispatchGroup()
                var lastError: Error?

                for sample in samples {
                    group.enter()
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    let hours = duration / 3600.0
                    let score = min(100.0, max(0.0, (hours / 8.0) * 100.0))

                    self.sleepDataManager.saveSleepEntry(from: sample,
                                                         sleepScore: score,
                                                         notes: nil) { result in
                        if case let .failure(error) = result {
                            lastError = error
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    if let error = lastError {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(()))
                    }
                }
            }
        }
    }
}
