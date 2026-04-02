// File: Modules/Home/HomeViewModel.swift
// ホーム画面用: 直近5件の表示DTO・未完了セッション。種目サマリ・総セット数はここで組み立てる。

import Foundation
import SwiftData

/// ホームの「直近の実績」1件分の表示用データ
struct HomeSessionDisplayItem: Identifiable {
    var id: UUID { sessionId }
    let sessionId: UUID
    let dateText: String
    let exerciseSummaryText: String
    let totalSetCount: Int
}

@Observable
final class HomeViewModel {
    var recentDisplayItems: [HomeSessionDisplayItem] = []
    var incompleteSession: WorkoutSession?
    /// 今週（週の開始〜現在）の完了セッション数
    var weekSessionCount: Int = 0
    /// 今週の総挙上（完了セッション）
    var weekTotalVolume: Double = 0
    /// 前週の完了セッション数
    var previousWeekSessionCount: Int = 0
    /// 前週の総挙上（完了セッション）
    var previousWeekTotalVolume: Double = 0
    /// 連続実施週数（今週から過去に、週1回以上の記録が続いている週の数）
    var streakWeeks: Int = 0
    /// カレンダー表示中の月の完了セッション数
    var sessionsInDisplayedMonthCount: Int = 0
    /// 最後に完了したワークアウトの日付表示（例: 3/21(金)）
    var lastCompletedSessionDateText: String?
    /// カレンダー表示中の月（任意日を含む）
    var calendarMonth: Date = Date()
    /// その月にトレーニング記録がある日（1...31）
    var trainingDaysInCalendarMonth: Set<Int> = []
    /// ユーザーが選択した日（既定: 今日）
    var selectedDate: Date = Date()
    /// 選択日の完了セッション一覧（詳細表示用）
    var sessionsForSelectedDate: [WorkoutSession] = []
    /// 今日の完了セッション一覧（ホームのログ表示用）
    var todaySessions: [WorkoutSession] = []
    /// 週のトレーニング目標に対するコメント（目標未設定時は nil）
    var frequencyGoalInsightMessage: String?
    /// 設定の週あたり目標セッション数（0＝未設定）。成長記録と共通。
    var weeklyWorkoutGoalSessions: Int = 0
    /// 今週達成したPR一覧 (PR, 種目名)
    var weeklyPRs: [(PersonalRecord, String)] = []
    var isLoading = false
    var errorMessage: String?

    private let workoutRepository: WorkoutRepositoryProtocol
    private let statsService: WorkoutStatsService
    private let settingsRepository: SettingsRepository
    private let modelContext: ModelContext

    init(workoutRepository: WorkoutRepositoryProtocol, statsService: WorkoutStatsService, modelContext: ModelContext) {
        self.workoutRepository = workoutRepository
        self.statsService = statsService
        self.settingsRepository = SettingsRepository(modelContext: modelContext)
        self.modelContext = modelContext
    }

    @available(*, deprecated, message: "Use init without templateRepository")
    init(workoutRepository: WorkoutRepositoryProtocol, templateRepository: TemplateRepositoryProtocol, statsService: WorkoutStatsService, modelContext: ModelContext) {
        self.workoutRepository = workoutRepository
        self.statsService = statsService
        self.settingsRepository = SettingsRepository(modelContext: modelContext)
        self.modelContext = modelContext
    }

    func loadRecentSessions() {
        isLoading = true
        errorMessage = nil
        do {
            let sessions = try workoutRepository.fetchRecentSessions(limit: 5, before: nil)
            incompleteSession = try workoutRepository.fetchIncompleteSessionStartedToday(referenceDate: Date())
            recentDisplayItems = sessions.map { makeDisplayItem(from: $0) }
            loadWeekSummary()
            loadMemoDashboardStats()
            loadCalendarRelatedStats()
            loadSessionsForSelectedDate()
            loadTodaySessions()
            loadWeeklyPRs()
            updateFrequencyGoalInsight()
        } catch {
            errorMessage = error.localizedDescription
            recentDisplayItems = []
            weekSessionCount = 0
            weekTotalVolume = 0
            previousWeekSessionCount = 0
            previousWeekTotalVolume = 0
            streakWeeks = 0
            sessionsInDisplayedMonthCount = 0
            lastCompletedSessionDateText = nil
            trainingDaysInCalendarMonth = []
            sessionsForSelectedDate = []
            todaySessions = []
            weeklyPRs = []
            frequencyGoalInsightMessage = nil
            weeklyWorkoutGoalSessions = 0
        }
        isLoading = false
    }

    /// カレンダーで月を変えたとき
    func setCalendarMonth(_ date: Date) {
        calendarMonth = date
        loadCalendarRelatedStats()
    }

    /// 日付選択（カレンダー・ピッカー）
    func selectDate(_ date: Date) {
        selectedDate = date
        let cal = Calendar.current
        if !cal.isDate(date, equalTo: calendarMonth, toGranularity: .month) {
            calendarMonth = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
            loadCalendarRelatedStats()
        }
        loadSessionsForSelectedDate()
    }

    private func loadWeekSummary() {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            weekSessionCount = 0
            weekTotalVolume = 0
            previousWeekSessionCount = 0
            previousWeekTotalVolume = 0
            streakWeeks = 0
            return
        }
        weekSessionCount = (try? statsService.workoutCount(from: weekStart, to: now)) ?? 0
        weekTotalVolume = (try? statsService.totalVolume(from: weekStart, to: now)) ?? 0
        if let previousWeekStart = cal.date(byAdding: .day, value: -7, to: weekStart),
           let previousWeekEnd = cal.date(byAdding: .second, value: -1, to: weekStart) {
            previousWeekSessionCount = (try? statsService.workoutCount(from: previousWeekStart, to: previousWeekEnd)) ?? 0
            previousWeekTotalVolume = (try? statsService.totalVolume(from: previousWeekStart, to: previousWeekEnd)) ?? 0
        } else {
            previousWeekSessionCount = 0
            previousWeekTotalVolume = 0
        }
        streakWeeks = (try? statsService.currentStreakWeeks()) ?? 0
    }

    private func loadMemoDashboardStats() {
        weeklyWorkoutGoalSessions = (try? settingsRepository.fetchUserPreference())?.weeklyWorkoutGoalSessions ?? 0
        if let last = try? workoutRepository.fetchRecentSessions(limit: 1, before: nil).first {
            lastCompletedSessionDateText = AppFormatters.formatDateWithWeekday(last.startedAt)
        } else {
            lastCompletedSessionDateText = nil
        }
    }

    private func loadWeeklyPRs() {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            weeklyPRs = []
            return
        }
        do {
            let prService = PersonalRecordService(modelContext: modelContext)
            let exRepo = ExerciseRepository(modelContext: modelContext)
            let recentPRs = try prService.fetchRecentPRs(limit: 50)
            weeklyPRs = recentPRs
                .filter { $0.achievedAt >= weekStart }
                .compactMap { pr in
                    guard let ex = try? exRepo.fetchExercise(by: pr.exerciseId) else { return nil }
                    return (pr, ex.name)
                }
        } catch {
            weeklyPRs = []
        }
    }

    private func loadCalendarRelatedStats() {
        trainingDaysInCalendarMonth = (try? statsService.completedSessionDaysOfMonth(containing: calendarMonth)) ?? []
        sessionsInDisplayedMonthCount = (try? statsService.completedSessionCount(inMonthContaining: calendarMonth)) ?? 0
    }

    private func loadSessionsForSelectedDate() {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: selectedDate)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else {
            sessionsForSelectedDate = []
            return
        }
        do {
            let sessions = try workoutRepository.fetchSessions(from: dayStart, to: dayEnd)
            sessionsForSelectedDate = sessions
        } catch {
            sessionsForSelectedDate = []
        }
    }

    private func loadTodaySessions() {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: Date())
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else {
            todaySessions = []
            return
        }
        todaySessions = (try? workoutRepository.fetchSessions(from: dayStart, to: dayEnd)) ?? []
    }

    /// セッションから表示用DTOを生成。種目名は最大3個まで、超えたら「他N種目」を付与。総セット数は全種目のセット合計。
    private func makeDisplayItem(from session: WorkoutSession) -> HomeSessionDisplayItem {
        let dateText = AppFormatters.formatDateWithWeekday(session.startedAt)
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        let names = exercises.compactMap { $0.exercise?.name }.filter { !$0.isEmpty }
        let exerciseSummaryText = Self.buildExerciseSummaryText(names: names)
        let totalSetCount = exercises.reduce(0) { $0 + $1.sets.count }
        return HomeSessionDisplayItem(
            sessionId: session.id,
            dateText: dateText,
            exerciseSummaryText: exerciseSummaryText,
            totalSetCount: totalSetCount
        )
    }

    /// 種目名を最大3個まで表示し、4個以上なら末尾に「他N種目」を付ける
    private static func buildExerciseSummaryText(names: [String]) -> String {
        guard !names.isEmpty else { return "—" }
        let show = Array(names.prefix(3))
        let suffix = names.count > 3 ? " 他\(names.count - 3)種目" : ""
        return show.joined(separator: "・") + suffix
    }

    private func updateFrequencyGoalInsight() {
        frequencyGoalInsightMessage = nil
        guard let pref = try? settingsRepository.fetchUserPreference() else { return }
        let goal = pref.weeklyWorkoutGoalSessions
        guard goal > 0 else { return }

        if weekSessionCount >= goal {
            frequencyGoalInsightMessage = String(
                format: String(localized: "home_frequency_goal_met_format"),
                goal,
                weekSessionCount
            )
            AnalyticsEventService.log(.retentionInsightShown(kind: "frequency_goal_met", source: "home"))
        } else {
            let remaining = goal - weekSessionCount
            frequencyGoalInsightMessage = String(
                format: String(localized: "home_frequency_goal_short_format"),
                weekSessionCount,
                goal,
                remaining
            )
            AnalyticsEventService.log(.retentionInsightShown(kind: "frequency_goal_short", source: "home"))
        }
    }
}
