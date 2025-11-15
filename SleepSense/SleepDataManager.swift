import Foundation
import CoreData
import HealthKit

final class SleepDataManager {
    static let shared = SleepDataManager()

    private let container: NSPersistentContainer
    private var viewContext: NSManagedObjectContext { container.viewContext }

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    // MARK: - Save

    /// Saves a SleepEntry created from a HealthKit sleep sample.
    ///
    /// The sample's startDate is used as the entry date and the duration (seconds)
    /// is stored in totalSleep. Other fields can be enriched later as you derive
    /// deep/REM/awake metrics from more detailed samples.
    func saveSleepEntry(from sample: HKCategorySample,
                        sleepScore: Double,
                        notes: String? = nil,
                        completion: ((Result<Void, Error>) -> Void)? = nil) {
        container.performBackgroundTask { context in
            do {
                let entry = SleepEntry(context: context)
                entry.id = UUID()
                entry.date = sample.startDate

                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                entry.totalSleep = duration
                entry.deepSleep = 0.0
                entry.remSleep = 0.0
                entry.awakeMinutes = 0.0
                entry.sleepScore = sleepScore
                entry.notes = notes

                try context.save()

                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                }
            } catch {
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Fetch

    /// Fetches SleepEntry objects for the given date range (inclusive).
    /// If start or end is nil, the predicate is open-ended on that side.
    func fetchEntries(from startDate: Date?,
                      to endDate: Date?,
                      completion: @escaping (Result<[SleepEntry], Error>) -> Void) {
        container.performBackgroundTask { [weak self] context in
            guard let self = self else { return }

            let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()

            var predicates: [NSPredicate] = []
            if let startDate = startDate {
                predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
            }
            if let endDate = endDate {
                predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
            }
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

            do {
                let results = try context.fetch(request)
                let objectIDs = results.map { $0.objectID }

                DispatchQueue.main.async {
                    self.viewContext.perform {
                        do {
                            let mainThreadResults: [SleepEntry] = try objectIDs.compactMap { objectID in
                                return try self.viewContext.existingObject(with: objectID) as? SleepEntry
                            }
                            completion(.success(mainThreadResults))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Update

    /// Updates the notes field for a SleepEntry with the given id.
    func updateNotes(for id: UUID,
                     notes: String?,
                     completion: ((Result<Void, Error>) -> Void)? = nil) {
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                if let entry = try context.fetch(request).first {
                    entry.notes = notes
                    try context.save()
                }

                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                }
            } catch {
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Delete

    /// Deletes the SleepEntry with the given id.
    func deleteEntry(for id: UUID,
                     completion: ((Result<Void, Error>) -> Void)? = nil) {
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                if let entry = try context.fetch(request).first {
                    context.delete(entry)
                    try context.save()
                }

                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                }
            } catch {
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
