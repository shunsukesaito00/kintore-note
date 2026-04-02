import Foundation
import SwiftData

struct CalendarDaySummaryDTO {
    let sessionCount: Int
    let totalVolume: Double
}

struct CalendarMonthSummaryDTO {
    let sessionCount: Int
    let totalVolume: Double
}

final class CalendarReviewService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func monthDaySummaries(monthAnchor: Date, bodyPart: String?) throws -> [Int: CalendarDaySummaryDTO] {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)),
              let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { return [:] }
        let sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: monthStart, to: monthEnd)
        var map: [Int: CalendarDaySummaryDTO] = [:]
        for session in sessions {
            let filteredExercises = filtered(workoutExercises: session.workoutExercises, bodyPart: bodyPart)
            guard !filteredExercises.isEmpty else { continue }
            let day = cal.component(.day, from: session.startedAt)
            let volume = filteredExercises.reduce(0.0) { total, we in
                total + we.sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }
            }
            let cur = map[day] ?? CalendarDaySummaryDTO(sessionCount: 0, totalVolume: 0)
            map[day] = CalendarDaySummaryDTO(sessionCount: cur.sessionCount + 1, totalVolume: cur.totalVolume + volume)
        }
        return map
    }

    func monthTotals(monthAnchor: Date, bodyPart: String?) throws -> CalendarMonthSummaryDTO {
        let summaries = try monthDaySummaries(monthAnchor: monthAnchor, bodyPart: bodyPart)
        return CalendarMonthSummaryDTO(
            sessionCount: summaries.values.reduce(0) { $0 + $1.sessionCount },
            totalVolume: summaries.values.reduce(0) { $0 + $1.totalVolume }
        )
    }

    private func filtered(workoutExercises: [WorkoutExercise], bodyPart: String?) -> [WorkoutExercise] {
        guard let bodyPart, !bodyPart.isEmpty else { return workoutExercises }
        return workoutExercises.filter { $0.exercise?.bodyPartTag == bodyPart }
    }
}
