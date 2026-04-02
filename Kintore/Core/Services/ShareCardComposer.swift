// File: Core/Services/ShareCardComposer.swift
// PR・セッション・月次の共有カード文面を生成。

import Foundation
import SwiftData

enum ShareCardComposer {
    struct ReviewShareCardDTO {
        let title: String
        let lines: [String]
    }

    static func reviewCardText(_ dto: ReviewShareCardDTO) -> String {
        ([dto.title] + dto.lines).joined(separator: "\n")
    }

    static func sessionCardText(session: WorkoutSession, weightUnit: String) -> String {
        let date = AppFormatters.formatDateWithWeekday(session.startedAt)
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        let exerciseCount = exercises.count
        let setCount = exercises.reduce(0) { $0 + $1.sets.count }
        let volume = Int(exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }
        })
        let header = String(localized: "share_card_session_title")
        let dateLine = String(format: String(localized: "share_card_date_fmt"), date)
        let exerciseLine = String(format: String(localized: "share_card_exercise_count_fmt"), exerciseCount)
        let setLine = String(format: String(localized: "share_card_set_count_fmt"), setCount)
        let volumeLine = String(format: String(localized: "share_card_total_volume_fmt"), volume, weightUnit)
        let tagLine = String(localized: "share_card_tag_replog")
        return [header, dateLine, exerciseLine, setLine, volumeLine, tagLine].joined(separator: "\n")
    }

    static func prCardText(session: WorkoutSession, weightUnit: String) -> String {
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        var bestLine = String(localized: "share_card_no_pr")
        var bestScore: Double = 0
        for exercise in exercises {
            let name = exercise.exercise?.name ?? "種目"
            for set in exercise.sets {
                let score = VolumeCalculator.volume(weight: set.weight, reps: set.reps)
                if score > bestScore, let weight = set.weight, let reps = set.reps {
                    bestScore = score
                    bestLine = String(
                        format: String(localized: "share_card_pr_line_fmt"),
                        name,
                        AppFormatters.formatWeightNumber(weight),
                        weightUnit,
                        reps
                    )
                }
            }
        }
        let header = String(localized: "share_card_pr_title")
        let tagLine = String(localized: "share_card_tag_pr")
        return [header, bestLine, tagLine].joined(separator: "\n")
    }

    static func growthSummaryText(viewModel: StatisticsViewModel, weightUnit: String) -> String {
        let header = String(localized: "share_card_growth_title")
        let sessions = String(format: String(localized: "share_card_growth_sessions_fmt"), viewModel.workoutCountWeek, viewModel.workoutCountMonth)
        let volume = String(format: String(localized: "share_card_growth_volume_fmt"), AppFormatters.formatWeightNumber(viewModel.totalVolume), weightUnit)
        let streak = String(format: String(localized: "share_card_growth_streak_fmt"), viewModel.currentStreakWeeks)
        let tag = String(localized: "share_card_tag_replog")
        return [header, sessions, volume, streak, tag].joined(separator: "\n")
    }

    static func monthlyCardText(modelContext: ModelContext, monthDate: Date, weightUnit: String) -> String {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthDate)) ?? monthDate
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthDate
        let stats = WorkoutStatsService(modelContext: modelContext)
        let count = (try? stats.workoutCount(from: monthStart, to: monthEnd)) ?? 0
        let volume = Int((try? stats.totalVolume(from: monthStart, to: monthEnd)) ?? 0)
        let monthLabel = AppFormatters.formatDate(monthStart).prefix(7)
        let header = String(format: String(localized: "share_card_monthly_title_fmt"), String(monthLabel))
        let workoutLine = String(format: String(localized: "share_card_workout_count_fmt"), count)
        let volumeLine = String(format: String(localized: "share_card_total_volume_fmt"), volume, weightUnit)
        let tagLine = String(localized: "share_card_tag_monthly")
        return reviewCardText(
            ReviewShareCardDTO(
                title: header,
                lines: [workoutLine, volumeLine, tagLine]
            )
        )
    }
}
