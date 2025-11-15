import Foundation
import HealthKit

final class HealthStore {
    static let shared = HealthStore()

    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current

    private init() {}

    // MARK: - Availability

    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Requests HealthKit authorization for reading sleep analysis and heart rate.
    /// Optionally requests write access for a custom sleep score type if provided.
    ///
    /// Info.plist must include:
    /// - NSHealthShareUsageDescription
    /// - NSHealthUpdateUsageDescription
    ///
    /// If you also use motion/activity for sleep detection, NSMotionUsageDescription is required.
    func requestAuthorization(includeSleepScoreWrite sleepScoreType: HKSampleType? = nil,
                              completion: @escaping (Bool, Error?) -> Void) {
        guard isHealthDataAvailable() else {
            completion(false, nil)
            return
        }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false, nil)
            return
        }

        let readTypes: Set<HKObjectType> = [sleepType, heartRateType]
        var writeTypes = Set<HKSampleType>()

        if let sleepScoreType = sleepScoreType {
            writeTypes.insert(sleepScoreType)
        }

        healthStore.requestAuthorization(toShare: writeTypes.isEmpty ? nil : writeTypes,
                                         read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    // MARK: - Sleep Queries

    /// Fetches sleep samples for the last night.
    /// The window is defined as the last 24 hours from now and filtered to sleepAnalysis samples.
    func fetchLastNightSleep(completion: @escaping (Result<[HKCategorySample], Error>) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(.success([]))
            return
        }

        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: endDate) else {
            completion(.success([]))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: sleepType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard self != nil else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            let categorySamples = samples as? [HKCategorySample] ?? []
            DispatchQueue.main.async {
                completion(.success(categorySamples))
            }
        }

        healthStore.execute(query)
    }

    /// Fetches sleep samples for the last 7 days and aggregates total sleep duration per day (in seconds).
    /// The result dictionary is keyed by the start-of-day date for each day.
    func fetchWeeklySleepAggregatedByDay(completion: @escaping (Result<[Date: TimeInterval], Error>) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(.success([:]))
            return
        }

        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            completion(.success([:]))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: sleepType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            let categorySamples = samples as? [HKCategorySample] ?? []
            var dailyTotals: [Date: TimeInterval] = [:]

            for sample in categorySamples {
                let startOfDay = self.calendar.startOfDay(for: sample.startDate)
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                dailyTotals[startOfDay, default: 0] += duration
            }

            DispatchQueue.main.async {
                completion(.success(dailyTotals))
            }
        }

        healthStore.execute(query)
    }
}
