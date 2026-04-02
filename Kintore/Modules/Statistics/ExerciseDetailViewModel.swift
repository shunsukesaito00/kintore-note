import Foundation
import SwiftData

@Observable
final class ExerciseDetailViewModel {
    var history: [(WorkoutExercise, WorkoutSession)] = []
    var loadError: String?
    var pr: PersonalRecord?
    var trendPoints: [ExerciseTrendPointDTO] = []
    var comparison = ExerciseComparisonDTO(previousVolumeDelta: 0, previousWeightDelta: 0, averageFiveVolumeDelta: 0)
    var exerciseKind: ExerciseKind = .strength
    var prMilestones: [ExercisePrMilestoneDTO] = []
    var kpi = ExerciseKpiDTO(
        recentDate: nil,
        recentWeight: 0,
        recentReps: 0,
        recentVolume: 0,
        maxWeight: 0,
        maxReps: 0,
        maxSessionVolume: 0,
        executionCount: 0,
        recentLongestDurationSeconds: 0,
        maxLongestDurationSeconds: 0,
        recentSessionTotalDurationSeconds: 0,
        maxSessionTotalDurationSeconds: 0,
        recentTotalDistanceMeters: 0,
        maxSingleDistanceMeters: 0,
        recentTotalCardioDurationSeconds: 0
    )

    func load(modelContext: ModelContext, exerciseId: UUID, start: Date?) {
        do {
            let reviewService = ExerciseReviewService(modelContext: modelContext)
            let exercise = try ExerciseRepository(modelContext: modelContext).fetchExercise(by: exerciseId)
            exerciseKind = ExerciseKind(stored: exercise?.exerciseKind)
            history = try reviewService.exerciseRecentHistory(exerciseId: exerciseId, limit: 100)
            trendPoints = try reviewService.exerciseTrendPoints(exerciseId: exerciseId, start: start, limit: 100)
            kpi = try reviewService.exerciseKpi(exerciseId: exerciseId, start: start, limit: 100)
            prMilestones = (try? reviewService.strengthVolumeMilestones(exerciseId: exerciseId, start: start, limit: 200)) ?? []
            comparison = ComparisonService().compareExerciseTrend(points: trendPoints, kind: exerciseKind)
            pr = try PersonalRecordService(modelContext: modelContext).fetchPersonalRecord(exerciseId: exerciseId)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            prMilestones = []
            trendPoints = []
        }
    }
}
