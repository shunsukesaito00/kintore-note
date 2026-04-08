// File: Core/Services/WidgetDataStore.swift
// Phase 14: ウィジェット用データ。App Group の UserDefaults に書き出し、ウィジェットが読む。

import Foundation
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

private let appGroupId = "group.com.shunsukesaito.kintore"
private let weekCountKey = "widget.weekCount"
private let latestPRKey = "widget.latestPR"
private let streakWeeksKey = "widget.streakWeeks"

enum WidgetDataStore {

    static var sharedSuite: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    /// メインアプリから呼ぶ。今週の実施回数・直近PR・連続実施週数を書き出す。
    static func update(weekCount: Int, latestPR: String?, streakWeeks: Int) {
        guard let suite = sharedSuite else { return }
        suite.set(weekCount, forKey: weekCountKey)
        suite.set(latestPR, forKey: latestPRKey)
        suite.set(streakWeeks, forKey: streakWeeksKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "RepLogWidget")
        #endif
    }

    /// ModelContext から集計して update する。ホーム表示後などに呼ぶ。
    static func updateFrom(modelContext: ModelContext) {
        let cal = Calendar.current
        let stats = WorkoutStatsService(modelContext: modelContext)
        let prService = PersonalRecordService(modelContext: modelContext)
        let exRepo = ExerciseRepository(modelContext: modelContext)
        let streakWeeks = (try? stats.currentStreakWeeks()) ?? 0
        let weekCount: Int
        if let interval = cal.dateInterval(of: .weekOfYear, for: Date()) {
            weekCount = (try? stats.workoutCount(from: interval.start, to: interval.end)) ?? 0
        } else {
            weekCount = 0
        }
        let unit = UserDefaults.standard.string(forKey: AppTheme.weightUnitStorageKey) ?? "kg"
        let prs = (try? prService.fetchRecentPRs(limit: 1)) ?? []
        let latestPR: String? = prs.first.flatMap { pr in
            guard let ex = try? exRepo.fetchExercise(by: pr.exerciseId) else { return nil }
            return "\(ex.name) \(Int(pr.weight))\(unit)×\(pr.reps)"
        }
        update(weekCount: weekCount, latestPR: latestPR, streakWeeks: streakWeeks)
        RetentionNotificationService.syncWeeklySummarySchedule(modelContext: modelContext)
    }

    /// ウィジェット側で読む用
    static func readWeekCount() -> Int {
        sharedSuite?.integer(forKey: weekCountKey) ?? 0
    }

    static func readLatestPR() -> String? {
        sharedSuite?.string(forKey: latestPRKey)
    }

    static func readStreakWeeks() -> Int {
        sharedSuite?.integer(forKey: streakWeeksKey) ?? 0
    }
}
