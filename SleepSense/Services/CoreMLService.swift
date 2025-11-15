import Foundation
import CoreML
import CoreData

final class CoreMLService {
    static let shared = CoreMLService()

    private let model: MLModel?

    private init() {
        // Try compiled model first (.mlmodelc), then fall back to raw .mlmodel
        if let url = Bundle.main.url(forResource: "SleepScorePredictor", withExtension: "mlmodelc") ??
                     Bundle.main.url(forResource: "SleepScorePredictor", withExtension: "mlmodel") {
            model = try? MLModel(contentsOf: url)
        } else {
            model = nil
        }
    }

    struct PredictionResult {
        let score: Double
        let recommendations: [String]
    }

    /// Predicts a sleep score from a SleepEntry using the Core ML model.
    /// Falls back to a heuristic score if the model is unavailable or fails.
    func predictScore(for entry: SleepEntry) -> PredictionResult {
        let duration = entry.totalSleep // seconds
        let total = max(duration, 1)
        let deep = max(entry.deepSleep, 0)
        let rem = max(entry.remSleep, 0)
        let awake = max(entry.awakeMinutes * 60.0, 0) // minutes -> seconds

        let deepPct = min(max(deep / total, 0), 1)
        let remPct = min(max(rem / total, 0), 1)
        let awakePct = min(max(awake / total, 0), 1)

        if let model = model {
            let features: [String: Any] = [
                "duration": duration,
                "deepPct": deepPct,
                "remPct": remPct,
                "awakePct": awakePct
            ]

            if let provider = try? MLDictionaryFeatureProvider(dictionary: features),
               let output = try? model.prediction(from: provider),
               let scoreValue = output.featureValue(for: "score")?.doubleValue {
                let clamped = max(0.0, min(100.0, scoreValue))
                return PredictionResult(score: clamped, recommendations: Self.recommendations(for: clamped, deepPct: deepPct, remPct: remPct, awakePct: awakePct))
            }
        }

        // Fallback heuristic: use duration and awakePct
        let hours = duration / 3600.0
        var score = (hours / 8.0) * 100.0
        score -= awakePct * 20.0
        let clamped = max(0.0, min(100.0, score))
        return PredictionResult(score: clamped, recommendations: Self.recommendations(for: clamped, deepPct: deepPct, remPct: remPct, awakePct: awakePct))
    }

    private static func recommendations(for score: Double,
                                        deepPct: Double,
                                        remPct: Double,
                                        awakePct: Double) -> [String] {
        var tips: [String] = []

        if score < 70 {
            tips.append("Aim for a consistent bedtime and wake-up time to stabilize your sleep schedule.")
        } else if score > 85 {
            tips.append("Your sleep quality looks strong. Keep your current routine consistent.")
        }

        if deepPct < 0.15 {
            tips.append("Consider winding down with relaxing activities to support deeper sleep (e.g., reading or light stretching).")
        }

        if remPct < 0.18 {
            tips.append("Try to reduce stress before bed; mindfulness or journaling can help improve REM-rich sleep.")
        }

        if awakePct > 0.1 {
            tips.append("Limit caffeine later in the day and avoid large meals close to bedtime to reduce nighttime awakenings.")
        }

        if tips.isEmpty {
            tips.append("Maintain your current routine and keep tracking your sleep to refine recommendations.")
        }

        return tips
    }
}
