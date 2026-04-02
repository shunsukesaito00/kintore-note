import Foundation
import SwiftData

struct ExerciseTrendPointDTO: Identifiable {
    var id: Date { date }
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let totalReps: Int
    let estimated1RM: Double?
    /// 時間種目: セッション内の合計秒
    let sessionTotalDurationSeconds: Int
    /// 時間種目: そのセッションの最長セット秒
    let sessionMaxDurationSeconds: Int
    /// 有酸素: セッション合計距離（m）
    let sessionTotalDistanceMeters: Double
    /// 有酸素: セッション合計時間（秒）
    let sessionTotalCardioDurationSeconds: Int
    /// 有酸素: 最大セット距離（m）
    let sessionMaxDistanceMeters: Double
}

/// 種目の「ベスト更新」とみなす区切り（そのセッションのベストセット体積が、それまでの全セッションを通じた最大を更新した日）
struct ExercisePrMilestoneDTO: Identifiable {
    var id: Date { date }
    let date: Date
    let weight: Double
    let reps: Int
    let volume: Double
}

struct ExerciseKpiDTO {
    let recentDate: Date?
    let recentWeight: Double
    let recentReps: Int
    let recentVolume: Double
    let maxWeight: Double
    let maxReps: Int
    let maxSessionVolume: Double
    let executionCount: Int
    /// 時間: 直近セッションの最長セット（秒）
    let recentLongestDurationSeconds: Int
    /// 時間: 期間内の最長セット（秒）
    let maxLongestDurationSeconds: Int
    /// 時間: 直近セッションの合計秒
    let recentSessionTotalDurationSeconds: Int
    /// 時間: 1 セッションあたりの最大合計秒
    let maxSessionTotalDurationSeconds: Int
    /// 有酸素: 直近セッション合計距離（m）
    let recentTotalDistanceMeters: Double
    /// 有酸素: 期間内の最大セット距離（m）
    let maxSingleDistanceMeters: Double
    /// 有酸素: 直近セッション合計時間（秒）
    let recentTotalCardioDurationSeconds: Int
}

final class ExerciseReviewService {
    private let repo: WorkoutRepository
    private let exerciseRepo: ExerciseRepository

    init(modelContext: ModelContext) {
        self.repo = WorkoutRepository(modelContext: modelContext)
        self.exerciseRepo = ExerciseRepository(modelContext: modelContext)
    }

    func exerciseRecentHistory(exerciseId: UUID, limit: Int = 100) throws -> [(WorkoutExercise, WorkoutSession)] {
        try repo.fetchHistoryForExercise(exerciseId: exerciseId, limit: limit, from: nil, to: nil)
    }

    func exerciseTrendPoints(exerciseId: UUID, start: Date?, limit: Int = 100) throws -> [ExerciseTrendPointDTO] {
        let exercise = try exerciseRepo.fetchExercise(by: exerciseId)
        let kind = ExerciseKind(stored: exercise?.exerciseKind)
        let history = try exerciseRecentHistory(exerciseId: exerciseId, limit: limit)
        return history.compactMap { we, session -> ExerciseTrendPointDTO? in
            let date = session.endedAt ?? session.startedAt
            if let start, date < start { return nil }
            let sets = we.sets.sorted { $0.orderIndex < $1.orderIndex }
            switch kind {
            case .strength, .weightedBodyweight:
                let wr = sets.filter { $0.weight != nil && $0.reps != nil }
                guard !wr.isEmpty else { return nil }
                let best1RM = wr.compactMap { VolumeCalculator.estimated1RM(weight: $0.weight, reps: $0.reps) }.max()
                return ExerciseTrendPointDTO(
                    date: date,
                    maxWeight: wr.map { $0.weight ?? 0 }.max() ?? 0,
                    totalVolume: wr.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) },
                    totalReps: wr.reduce(0) { $0 + max(0, $1.reps ?? 0) },
                    estimated1RM: best1RM,
                    sessionTotalDurationSeconds: 0,
                    sessionMaxDurationSeconds: 0,
                    sessionTotalDistanceMeters: 0,
                    sessionTotalCardioDurationSeconds: 0,
                    sessionMaxDistanceMeters: 0
                )
            case .time:
                let durSets = sets.filter { ($0.durationSeconds ?? 0) > 0 }
                guard !durSets.isEmpty else { return nil }
                let total = durSets.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
                let maxD = durSets.map { $0.durationSeconds ?? 0 }.max() ?? 0
                return ExerciseTrendPointDTO(
                    date: date,
                    maxWeight: 0,
                    totalVolume: 0,
                    totalReps: 0,
                    estimated1RM: nil,
                    sessionTotalDurationSeconds: total,
                    sessionMaxDurationSeconds: maxD,
                    sessionTotalDistanceMeters: 0,
                    sessionTotalCardioDurationSeconds: 0,
                    sessionMaxDistanceMeters: 0
                )
            case .cardio:
                let c = sets.filter { ($0.distanceMeters ?? 0) > 0 || ($0.durationSeconds ?? 0) > 0 }
                guard !c.isEmpty else { return nil }
                let totalDist = c.reduce(0.0) { $0 + ($1.distanceMeters ?? 0) }
                let totalTime = c.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
                let maxDist = c.map { $0.distanceMeters ?? 0 }.max() ?? 0
                return ExerciseTrendPointDTO(
                    date: date,
                    maxWeight: 0,
                    totalVolume: 0,
                    totalReps: 0,
                    estimated1RM: nil,
                    sessionTotalDurationSeconds: 0,
                    sessionMaxDurationSeconds: 0,
                    sessionTotalDistanceMeters: totalDist,
                    sessionTotalCardioDurationSeconds: totalTime,
                    sessionMaxDistanceMeters: maxDist
                )
            }
        }
        .sorted { $0.date < $1.date }
    }

    func exerciseKpi(exerciseId: UUID, start: Date?, limit: Int = 100) throws -> ExerciseKpiDTO {
        let exercise = try exerciseRepo.fetchExercise(by: exerciseId)
        let kind = ExerciseKind(stored: exercise?.exerciseKind)
        let points = try exerciseTrendPoints(exerciseId: exerciseId, start: start, limit: limit)
        let history = try exerciseRecentHistory(exerciseId: exerciseId, limit: limit)
        let recent = history.first
        let recentDate = recent.map { $0.1.endedAt ?? $0.1.startedAt }

        switch kind {
        case .strength, .weightedBodyweight:
            let recentSet = recent?.0.sets
                .filter { $0.weight != nil && $0.reps != nil }
                .max(by: { VolumeCalculator.volume(weight: $0.weight, reps: $0.reps) < VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) })
            return ExerciseKpiDTO(
                recentDate: recentDate,
                recentWeight: recentSet?.weight ?? 0,
                recentReps: recentSet?.reps ?? 0,
                recentVolume: points.last?.totalVolume ?? 0,
                maxWeight: points.map(\.maxWeight).max() ?? 0,
                maxReps: history.flatMap { $0.0.sets }.map { max(0, $0.reps ?? 0) }.max() ?? 0,
                maxSessionVolume: points.map(\.totalVolume).max() ?? 0,
                executionCount: points.count,
                recentLongestDurationSeconds: 0,
                maxLongestDurationSeconds: 0,
                recentSessionTotalDurationSeconds: 0,
                maxSessionTotalDurationSeconds: 0,
                recentTotalDistanceMeters: 0,
                maxSingleDistanceMeters: 0,
                recentTotalCardioDurationSeconds: 0
            )
        case .time:
            let maxLong = points.map(\.sessionMaxDurationSeconds).max() ?? 0
            let maxTotal = points.map(\.sessionTotalDurationSeconds).max() ?? 0
            let recentSets = recent?.0.sets ?? []
            let recentMax = recentSets.map { $0.durationSeconds ?? 0 }.max() ?? 0
            let recentSum = recentSets.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return ExerciseKpiDTO(
                recentDate: recentDate,
                recentWeight: 0,
                recentReps: 0,
                recentVolume: 0,
                maxWeight: 0,
                maxReps: 0,
                maxSessionVolume: 0,
                executionCount: points.count,
                recentLongestDurationSeconds: recentMax,
                maxLongestDurationSeconds: maxLong,
                recentSessionTotalDurationSeconds: recentSum,
                maxSessionTotalDurationSeconds: maxTotal,
                recentTotalDistanceMeters: 0,
                maxSingleDistanceMeters: 0,
                recentTotalCardioDurationSeconds: 0
            )
        case .cardio:
            let maxDist = points.map(\.sessionMaxDistanceMeters).max() ?? 0
            let recentSets = recent?.0.sets ?? []
            let rDist = recentSets.reduce(0.0) { $0 + ($1.distanceMeters ?? 0) }
            let rTime = recentSets.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
            return ExerciseKpiDTO(
                recentDate: recentDate,
                recentWeight: 0,
                recentReps: 0,
                recentVolume: 0,
                maxWeight: 0,
                maxReps: 0,
                maxSessionVolume: 0,
                executionCount: points.count,
                recentLongestDurationSeconds: 0,
                maxLongestDurationSeconds: 0,
                recentSessionTotalDurationSeconds: 0,
                maxSessionTotalDurationSeconds: 0,
                recentTotalDistanceMeters: rDist,
                maxSingleDistanceMeters: maxDist,
                recentTotalCardioDurationSeconds: rTime
            )
        }
    }

    /// 重量×回の種目のみ。時系列で、そのセッションのベストセット体積が過去最大を更新した日の一覧（ベスト更新履歴）。
    func strengthVolumeMilestones(exerciseId: UUID, start: Date?, limit: Int = 200) throws -> [ExercisePrMilestoneDTO] {
        let exercise = try exerciseRepo.fetchExercise(by: exerciseId)
        let kind = ExerciseKind(stored: exercise?.exerciseKind)
        guard kind == .strength || kind == .weightedBodyweight else { return [] }
        var history = try exerciseRecentHistory(exerciseId: exerciseId, limit: limit)
        history.reverse()
        var runningMax: Double = 0
        var milestones: [ExercisePrMilestoneDTO] = []
        for (we, session) in history {
            let date = session.endedAt ?? session.startedAt
            let sets = we.sets.sorted { $0.orderIndex < $1.orderIndex }
            let wr = sets.filter { $0.weight != nil && $0.reps != nil }
            guard let best = wr.max(by: {
                VolumeCalculator.volume(weight: $0.weight, reps: $0.reps) < VolumeCalculator.volume(weight: $1.weight, reps: $1.reps)
            }) else { continue }
            let vol = VolumeCalculator.volume(weight: best.weight, reps: best.reps)
            guard vol > 0 else { continue }
            if vol > runningMax {
                runningMax = vol
                if start.map({ date >= $0 }) ?? true {
                    milestones.append(
                        ExercisePrMilestoneDTO(
                            date: date,
                            weight: best.weight ?? 0,
                            reps: best.reps ?? 0,
                            volume: vol
                        )
                    )
                }
            }
        }
        return milestones.sorted { $0.date < $1.date }
    }
}
