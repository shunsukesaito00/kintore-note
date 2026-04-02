import Foundation

struct ExerciseComparisonDTO {
    let previousVolumeDelta: Double
    let previousWeightDelta: Double
    let averageFiveVolumeDelta: Double
}

final class ComparisonService {
    func compareExerciseTrend(points: [ExerciseTrendPointDTO], kind: ExerciseKind) -> ExerciseComparisonDTO {
        guard let latest = points.last else {
            return ExerciseComparisonDTO(previousVolumeDelta: 0, previousWeightDelta: 0, averageFiveVolumeDelta: 0)
        }
        let previous = points.dropLast().last
        let lastFive = points.suffix(5)

        switch kind {
        case .strength, .weightedBodyweight:
            let averageVolume = lastFive.isEmpty
                ? latest.totalVolume
                : lastFive.reduce(0.0) { $0 + $1.totalVolume } / Double(lastFive.count)
            return ExerciseComparisonDTO(
                previousVolumeDelta: latest.totalVolume - (previous?.totalVolume ?? latest.totalVolume),
                previousWeightDelta: latest.maxWeight - (previous?.maxWeight ?? latest.maxWeight),
                averageFiveVolumeDelta: latest.totalVolume - averageVolume
            )
        case .time:
            let avg5: Double
            if lastFive.isEmpty {
                avg5 = Double(latest.sessionTotalDurationSeconds)
            } else {
                let sum = lastFive.reduce(0.0) { $0 + Double($1.sessionTotalDurationSeconds) }
                avg5 = sum / Double(lastFive.count)
            }
            let latestTot = Double(latest.sessionTotalDurationSeconds)
            let prevTot = Double(previous?.sessionTotalDurationSeconds ?? latest.sessionTotalDurationSeconds)
            let latestMax = Double(latest.sessionMaxDurationSeconds)
            let prevMax = Double(previous?.sessionMaxDurationSeconds ?? latest.sessionMaxDurationSeconds)
            return ExerciseComparisonDTO(
                previousVolumeDelta: latestTot - prevTot,
                previousWeightDelta: latestMax - prevMax,
                averageFiveVolumeDelta: latestTot - avg5
            )
        case .cardio:
            let avg5 = lastFive.isEmpty
                ? latest.sessionTotalDistanceMeters
                : lastFive.reduce(0.0) { $0 + $1.sessionTotalDistanceMeters } / Double(lastFive.count)
            let latestDist = latest.sessionTotalDistanceMeters
            let prevDist = previous?.sessionTotalDistanceMeters ?? latestDist
            let latestMaxD = latest.sessionMaxDistanceMeters
            let prevMaxD = previous?.sessionMaxDistanceMeters ?? latestMaxD
            return ExerciseComparisonDTO(
                previousVolumeDelta: latestDist - prevDist,
                previousWeightDelta: latestMaxD - prevMaxD,
                averageFiveVolumeDelta: latestDist - avg5
            )
        }
    }
}
