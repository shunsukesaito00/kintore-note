import Foundation
import SwiftData

struct BodyPartExercisePR: Identifiable {
    let id: UUID
    let exerciseName: String
    let exerciseKind: ExerciseKind
    let pr: PersonalRecord?
}

@Observable
final class BodyPartGrowthViewModel {
    var exercisePRs: [BodyPartExercisePR] = []
    var weeklyFrequency: [(weekStart: Date, count: Int)] = []
    var averagePerWeek: Double = 0

    func load(
        modelContext: ModelContext,
        bodyPart: String,
        weekCount: Int
    ) {
        do {
            let exRepo = ExerciseRepository(modelContext: modelContext)
            let stats = WorkoutStatsService(modelContext: modelContext)
            let allExercises = try exRepo.fetchAllExercises()
            let filtered = allExercises.filter { $0.bodyPartTag == bodyPart }

            let prMap = try stats.fetchAllPRsAsMap(modelContext: modelContext)

            exercisePRs = filtered.map { ex in
                let kind = ExerciseKind(stored: ex.exerciseKind)
                let pr = kind.participatesInPersonalRecord ? prMap[ex.id] : nil
                return BodyPartExercisePR(
                    id: ex.id,
                    exerciseName: ex.name,
                    exerciseKind: kind,
                    pr: pr
                )
            }
            .sorted { lhs, rhs in
                if lhs.pr != nil && rhs.pr == nil { return true }
                if lhs.pr == nil && rhs.pr != nil { return false }
                if let lv = lhs.pr?.volume, let rv = rhs.pr?.volume { return lv > rv }
                return lhs.exerciseName < rhs.exerciseName
            }

            weeklyFrequency = try stats.weeklySessionCountsForBodyPart(bodyPart, weekCount: weekCount)
            let total = weeklyFrequency.reduce(0) { $0 + $1.count }
            averagePerWeek = weekCount > 0 ? Double(total) / Double(weekCount) : 0
        } catch {
            exercisePRs = []
            weeklyFrequency = []
            averagePerWeek = 0
        }
    }
}
