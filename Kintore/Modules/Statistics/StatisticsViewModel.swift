// File: Modules/Statistics/StatisticsViewModel.swift
// 統計画面のデータ取得・集計結果の保持。View は表示専念。ストリークは WorkoutStatsService.currentStreakWeeks を唯一参照。

import Foundation
import SwiftData

@Observable
final class StatisticsViewModel {
    var workoutCountAll: Int = 0
    /// 今週（カレンダー週の開始〜現在まで）の完了セッション数。ホームの週目標と同一基準。
    var workoutCountWeek: Int = 0
    var workoutCountMonth: Int = 0
    /// 設定の「週のトレーニング目標」（0＝未設定）
    var weeklyWorkoutGoalSessions: Int = 0
    var totalVolume: Double = 0
    var currentStreakWeeks: Int = 0
    var weeklySessionCounts: [(weekStart: Date, count: Int)] = []
    var monthlyVolumes: [(monthStart: Date, volume: Double)] = []
    var weeklyTotalVolumes: [(weekStart: Date, volume: Double)] = []
    var bodyPartCounts: [(bodyPart: String, count: Int)] = []
    var recentPRs: [(PersonalRecord, String)] = []
    var allExercises: [Exercise] = []
    var weeklyVolumeByPart: [(weekStart: Date, bodyPart: String, volume: Double)] = []
    /// 全期間または無料時は直近1ヶ月窓（`bodyPartCounts` と揃える）
    var bodyPartVolumes: [(bodyPart: String, volume: Double)] = []
    var bodyPartSetCounts: [(bodyPart: String, count: Int)] = []
    var bodyPartRepCounts: [(bodyPart: String, reps: Int)] = []
    var thisWeekVolumeByPart: [(bodyPart: String, volume: Double)] = []
    var monthlyVolumeByPart: [(monthStart: Date, bodyPart: String, volume: Double)] = []
    /// 直近14日で最大部位負荷の20%未満の標準部位
    var undertrainedBodyParts: [String] = []
    var recent30DaysTrainingCount: Int = 0
    var averageDuration: Double = 0
    var averageSets: Double = 0
    var averageExercises: Double = 0

    // MARK: - Delta comparison (Phase B)
    var previousWeekSessionCount: Int = 0
    var weekSessionDelta: Int = 0
    var previousMonthVolume: Double = 0
    var monthVolumeDelta: Double = 0
    var weekVolume: Double = 0
    var previousWeekVolume: Double = 0
    var weekVolumeDelta: Double = 0

    var monthVolume: Double = 0
    /// 期間内に達成日がある PR 件数（種目ベストがその期間に更新された数）
    var prAchievedWeek: Int = 0
    var prAchievedMonth: Int = 0
    /// PR レコード総数（全期間・種目数に相当）
    var prRecordCountAll: Int = 0

    // MARK: - Heatmap (Phase B)
    var trainingDaysLast12Weeks: [Date: Int] = [:]

    // MARK: - Insight (Phase A)
    var insightMessage: String?
    var insightIcon: String = "lightbulb.fill"

    private(set) var graphsLimitedToOneMonth = false
    private(set) var chartWeekCount = 12
    private(set) var chartMonthCount = 6

    func load(modelContext: ModelContext, isPremium: Bool) {
        do {
            let stats = WorkoutStatsService(modelContext: modelContext)
            let prService = PersonalRecordService(modelContext: modelContext)
            let exRepo = ExerciseRepository(modelContext: modelContext)

            let calendar = Calendar.current
            let now = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now

            graphsLimitedToOneMonth = !isPremium
            chartWeekCount = isPremium ? 12 : 5
            chartMonthCount = isPremium ? 6 : 1

            let settingsRepo = SettingsRepository(modelContext: modelContext)
            weeklyWorkoutGoalSessions = (try? settingsRepo.fetchUserPreference())?.weeklyWorkoutGoalSessions ?? 0

            workoutCountAll = try stats.workoutCount(from: nil, to: nil)
            workoutCountWeek = try stats.workoutCount(from: weekStart, to: now)
            workoutCountMonth = try stats.workoutCount(from: monthStart, to: monthEnd)

            totalVolume = try stats.totalVolumeAllCompletedSessions()

            let prs = try prService.fetchRecentPRs(limit: 20)
            recentPRs = prs.compactMap { pr -> (PersonalRecord, String)? in
                guard let ex = try? exRepo.fetchExercise(by: pr.exerciseId) else { return nil }
                return (pr, ex.name)
            }

            if isPremium {
                bodyPartCounts = try stats.bodyPartSessionCounts()
            } else {
                let windowStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                bodyPartCounts = try stats.bodyPartSessionCounts(in: (start: windowStart, end: now))
            }
            if isPremium {
                let agg = try stats.bodyPartAggregates(in: nil)
                bodyPartVolumes = agg.volumes
                bodyPartSetCounts = agg.setCounts
                bodyPartRepCounts = agg.repCounts
            } else {
                let windowStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                let agg = try stats.bodyPartAggregates(in: (start: windowStart, end: now))
                bodyPartVolumes = agg.volumes
                bodyPartSetCounts = agg.setCounts
                bodyPartRepCounts = agg.repCounts
            }
            thisWeekVolumeByPart = try stats.thisWeekVolumeByBodyPart()
            monthlyVolumeByPart = try stats.monthlyVolumeByBodyPart(monthCount: chartMonthCount)
            undertrainedBodyParts = try stats.undertrainedCanonicalBodyParts()
            allExercises = try exRepo.fetchAllExercises()

            weeklyVolumeByPart = try stats.weeklyVolumeByBodyPart(weekCount: chartWeekCount)
            monthlyVolumes = try stats.monthlyVolumes(monthCount: chartMonthCount)
            weeklyTotalVolumes = try stats.weeklyTotalVolumes(weekCount: chartWeekCount)

            weeklySessionCounts = try stats.weeklySessionCounts(weekCount: chartWeekCount)
            currentStreakWeeks = try stats.currentStreakWeeks()
            recent30DaysTrainingCount = try stats.trainingDaysCount(lastDays: 30)
            averageDuration = try stats.averageSessionDuration()
            averageSets = try stats.averageSetCountPerSession()
            averageExercises = try stats.averageExerciseCountPerSession()

            // Delta: previous week session count
            let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? weekStart
            previousWeekSessionCount = try stats.workoutCount(from: prevWeekStart, to: weekStart)
            weekSessionDelta = workoutCountWeek - previousWeekSessionCount

            // Delta: week volume
            weekVolume = try stats.totalVolume(from: weekStart, to: now)
            previousWeekVolume = try stats.totalVolume(from: prevWeekStart, to: weekStart)
            weekVolumeDelta = weekVolume - previousWeekVolume

            // Delta: month volume
            let prevMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
            previousMonthVolume = try stats.totalVolume(from: prevMonthStart, to: monthStart)
            let currentMonthVolume = try stats.totalVolume(from: monthStart, to: monthEnd)
            monthVolume = currentMonthVolume
            monthVolumeDelta = currentMonthVolume - previousMonthVolume

            prAchievedWeek = try prService.countAchievedBetween(start: weekStart, end: now)
            prAchievedMonth = try prService.countAchievedBetween(start: monthStart, end: monthEnd)
            prRecordCountAll = try prService.countAllRecords()

            // Heatmap: training days per day for last 12 weeks
            trainingDaysLast12Weeks = try stats.dailySessionCounts(weekCount: 12)

            // Generate insight
            updateInsight()
        } catch {
            resetToDefaults()
        }
    }

    // MARK: - Insight generation

    private func updateInsight() {
        let topPart = bodyPartCounts.first?.bodyPart

        if currentStreakWeeks >= 4 {
            insightMessage = String(format: String(localized: "insight_streak_strong"), currentStreakWeeks)
            insightIcon = "flame.fill"
            return
        }

        if weekSessionDelta > 0 {
            insightMessage = String(format: String(localized: "insight_session_up"), weekSessionDelta)
            insightIcon = "arrow.up.right"
            return
        }

        if weekVolumeDelta > 0, previousWeekVolume > 0 {
            let pct = Int((weekVolumeDelta / previousWeekVolume) * 100)
            if pct >= 5 {
                insightMessage = String(format: String(localized: "insight_volume_up"), pct)
                insightIcon = "chart.line.uptrend.xyaxis"
                return
            }
        }

        if let part = topPart, !part.isEmpty {
            insightMessage = String(format: String(localized: "insight_top_body_part"), part)
            insightIcon = "figure.strengthtraining.traditional"
            return
        }

        if !recentPRs.isEmpty {
            insightMessage = String(format: String(localized: "insight_recent_pr"), recentPRs.first?.1 ?? "")
            insightIcon = "trophy.fill"
            return
        }

        if workoutCountAll == 0 {
            insightMessage = String(localized: "insight_get_started")
            insightIcon = "plus.circle.fill"
            return
        }

        insightMessage = nil
    }

    private func resetToDefaults() {
        workoutCountAll = 0
        workoutCountWeek = 0
        workoutCountMonth = 0
        weeklyWorkoutGoalSessions = 0
        totalVolume = 0
        currentStreakWeeks = 0
        weeklySessionCounts = []
        monthlyVolumes = []
        weeklyTotalVolumes = []
        bodyPartCounts = []
        recentPRs = []
        allExercises = []
        weeklyVolumeByPart = []
        bodyPartVolumes = []
        bodyPartSetCounts = []
        bodyPartRepCounts = []
        thisWeekVolumeByPart = []
        monthlyVolumeByPart = []
        undertrainedBodyParts = []
        recent30DaysTrainingCount = 0
        averageDuration = 0
        averageSets = 0
        averageExercises = 0
        graphsLimitedToOneMonth = false
        chartWeekCount = 12
        chartMonthCount = 6
        previousWeekSessionCount = 0
        weekSessionDelta = 0
        previousMonthVolume = 0
        monthVolumeDelta = 0
        weekVolume = 0
        previousWeekVolume = 0
        weekVolumeDelta = 0

        monthVolume = 0
        prAchievedWeek = 0
        prAchievedMonth = 0
        prRecordCountAll = 0
        trainingDaysLast12Weeks = [:]
        insightMessage = nil
    }
}
