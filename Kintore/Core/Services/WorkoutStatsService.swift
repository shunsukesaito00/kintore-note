// File: Core/Services/WorkoutStatsService.swift
// 総挙上重量計算・ワークアウト回数集計の基礎。

import Foundation
import SwiftData

final class WorkoutStatsService {
    private let modelContext: ModelContext

    /// 統計・セレクタで揃える標準部位（胸〜有酸素）。
    static let canonicalBodyParts: [String] = ["胸", "背中", "脚", "肩", "腕", "体幹", "有酸素"]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 部位別の総負荷・セット数・レップ数（筋力・加重自体重の reps のみ）をまとめて集計。
    struct BodyPartAggregates {
        let volumes: [(bodyPart: String, volume: Double)]
        let setCounts: [(bodyPart: String, count: Int)]
        let repCounts: [(bodyPart: String, reps: Int)]
    }

    /// 1 セットの総挙上 = weight × reps。nil は 0。正本は VolumeCalculator。
    static func volumeForSet(weight: Double?, reps: Int?) -> Double {
        VolumeCalculator.volume(weight: weight, reps: reps)
    }

    /// 1 種目（WorkoutExercise）の総挙上（時間・有酸素は 0）
    func totalVolume(for workoutExercise: WorkoutExercise) -> Double {
        let kind = ExerciseKind(stored: workoutExercise.exercise?.exerciseKind)
        guard kind.usesLoadVolume else { return 0 }
        return workoutExercise.sets.reduce(0) { sum, set in
            sum + Self.volumeForSet(weight: set.weight, reps: set.reps)
        }
    }

    /// 1 セッションの総挙上
    func totalVolume(for session: WorkoutSession) -> Double {
        session.workoutExercises.reduce(0) { sum, we in
            sum + totalVolume(for: we)
        }
    }

    /// 完了セッションの総挙上を全期間集計。大量データでもメモリに載せすぎないようページング取得。
    func totalVolumeAllCompletedSessions() throws -> Double {
        let repo = WorkoutRepository(modelContext: modelContext)
        var sum: Double = 0
        var before: Date? = nil
        let pageSize = 200
        while true {
            let batch = try repo.fetchRecentSessions(limit: pageSize, before: before)
            if batch.isEmpty { break }
            for session in batch {
                sum += totalVolume(for: session)
            }
            if batch.count < pageSize { break }
            before = batch.last?.startedAt
        }
        return sum
    }

    /// 期間内の全セッションの総挙上合計（完了済みのみ）
    func totalVolume(from start: Date, to end: Date) throws -> Double {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= start && session.startedAt <= end
            }
        )
        let sessions = try modelContext.fetch(descriptor)
        return sessions.reduce(0) { sum, session in sum + totalVolume(for: session) }
    }

    /// ワークアウト回数（完了済みセッション数）。期間指定可。nil の場合は全期間。
    func workoutCount(from start: Date? = nil, to end: Date? = nil) throws -> Int {
        if let s = start, let e = end {
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { session in
                    session.endedAt != nil && session.startedAt >= s && session.startedAt <= e
                }
            )
            return try modelContext.fetchCount(descriptor)
        } else {
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { $0.endedAt != nil }
            )
            return try modelContext.fetchCount(descriptor)
        }
    }

    /// 部位別実施回数（完了セッション内でその部位の種目が含まれたセッション数）。全期間。
    func bodyPartSessionCounts() throws -> [(bodyPart: String, count: Int)] {
        let repo = WorkoutRepository(modelContext: modelContext)
        var partToSessions: [String: Set<UUID>] = [:]
        var before: Date? = nil
        let pageSize = 200
        while true {
            let batch = try repo.fetchRecentSessions(limit: pageSize, before: before)
            if batch.isEmpty { break }
            for session in batch {
                let parts = Set(session.workoutExercises.compactMap { $0.exercise?.bodyPartTag }.filter { !$0.isEmpty })
                for p in parts {
                    partToSessions[p, default: []].insert(session.id)
                }
            }
            if batch.count < pageSize { break }
            before = batch.last?.startedAt
        }
        return partToSessions.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    /// 部位別実施回数。`startedAt` が \[start, end) の完了セッションのみ（無料統計の直近1ヶ月など）。
    func bodyPartSessionCounts(in window: (start: Date, end: Date)) throws -> [(bodyPart: String, count: Int)] {
        let repo = WorkoutRepository(modelContext: modelContext)
        let sessions = try repo.fetchSessions(from: window.start, to: window.end)
        var partToSessions: [String: Set<UUID>] = [:]
        for session in sessions {
            let parts = Set(session.workoutExercises.compactMap { $0.exercise?.bodyPartTag }.filter { !$0.isEmpty })
            for p in parts {
                partToSessions[p, default: []].insert(session.id)
            }
        }
        return partToSessions.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    /// 期間内の部位別総負荷・セット数・レップ数（筋力・加重の reps のみ）。`window == nil` のとき全期間（ページング）。
    func bodyPartAggregates(in window: (start: Date, end: Date)? = nil) throws -> BodyPartAggregates {
        let repo = WorkoutRepository(modelContext: modelContext)
        var volMap: [String: Double] = [:]
        var setMap: [String: Int] = [:]
        var repMap: [String: Int] = [:]

        func accumulate(session: WorkoutSession) {
            for we in session.workoutExercises {
                let part = we.exercise?.bodyPartTag.isEmpty == false ? we.exercise!.bodyPartTag : "その他"
                let kind = ExerciseKind(stored: we.exercise?.exerciseKind)
                setMap[part, default: 0] += we.sets.count
                volMap[part, default: 0] += totalVolume(for: we)
                if kind == .strength || kind == .weightedBodyweight {
                    for set in we.sets {
                        repMap[part, default: 0] += max(0, set.reps ?? 0)
                    }
                }
            }
        }

        if let window {
            let sessions = try repo.fetchSessions(from: window.start, to: window.end)
            for session in sessions { accumulate(session: session) }
        } else {
            var before: Date? = nil
            let pageSize = 200
            while true {
                let batch = try repo.fetchRecentSessions(limit: pageSize, before: before)
                if batch.isEmpty { break }
                for session in batch { accumulate(session: session) }
                if batch.count < pageSize { break }
                before = batch.last?.startedAt
            }
        }

        let volumes = volMap.map { (bodyPart: $0.key, volume: $0.value) }.sorted { $0.volume > $1.volume }
        let sets = setMap.map { (bodyPart: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
        let reps = repMap.map { (bodyPart: $0.key, reps: $0.value) }.sorted { $0.reps > $1.reps }
        return BodyPartAggregates(volumes: volumes, setCounts: sets, repCounts: reps)
    }

    /// 今週（カレンダー週）の部位別総負荷。
    func thisWeekVolumeByBodyPart() throws -> [(bodyPart: String, volume: Double)] {
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { return [] }
        let sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: weekStart, to: weekEnd)
        var map: [String: Double] = [:]
        for session in sessions {
            for we in session.workoutExercises {
                let part = we.exercise?.bodyPartTag.isEmpty == false ? we.exercise!.bodyPartTag : "その他"
                map[part, default: 0] += totalVolume(for: we)
            }
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    /// 月ごとの部位別総負荷（直近 monthCount ヶ月）。月の開始日昇順。
    func monthlyVolumeByBodyPart(monthCount: Int = 6) throws -> [(monthStart: Date, bodyPart: String, volume: Double)] {
        let cal = Calendar.current
        guard let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date())) else { return [] }
        var flat: [(Date, String, Double)] = []
        for monthOffset in 0..<monthCount {
            guard let monthStart = cal.date(byAdding: .month, value: -monthOffset, to: thisMonthStart),
                  let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: monthStart, to: monthEnd)
            var partVol: [String: Double] = [:]
            for session in sessions {
                for we in session.workoutExercises {
                    let part = we.exercise?.bodyPartTag.isEmpty == false ? we.exercise!.bodyPartTag : "その他"
                    let vol = totalVolume(for: we)
                    if vol > 0 {
                        partVol[part, default: 0] += vol
                    }
                }
            }
            for (part, vol) in partVol {
                flat.append((monthStart, part, vol))
            }
        }
        return flat.sorted { $0.0 < $1.0 }
    }

    /// 直近 `lastDays` 日で、最大部位負荷の `thresholdFraction` 未満の標準部位（不足しやすい候補）。
    func undertrainedCanonicalBodyParts(lastDays: Int = 14, thresholdFraction: Double = 0.2) throws -> [String] {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -lastDays, to: now) ?? now
        let agg = try bodyPartAggregates(in: (start: start, end: now))
        let volByPart = Dictionary(uniqueKeysWithValues: agg.volumes.map { ($0.bodyPart, $0.volume) })
        let canonical = Self.canonicalBodyParts
        let maxV = canonical.map { volByPart[$0] ?? 0 }.max() ?? 0
        if maxV <= 0 { return [] }
        let threshold = maxV * thresholdFraction
        return canonical.filter { (volByPart[$0] ?? 0) < threshold }
    }

    /// 週ごとの部位別ボリューム（直近 weekCount 週）。スタックバー用。(weekStart, bodyPart, volume)
    func weeklyVolumeByBodyPart(weekCount: Int = 12) throws -> [(weekStart: Date, bodyPart: String, volume: Double)] {
        let cal = Calendar.current
        let now = Date()
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        guard let rangeStart = cal.date(byAdding: .weekOfYear, value: -(weekCount + 1), to: thisWeekStart) else {
            return []
        }
        let rangeStartBound = rangeStart
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= rangeStartBound
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)
        var result: [(Date, String, Double)] = []
        for weekOffset in 0..<weekCount {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: thisWeekStart),
                  let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            for session in sessions {
                guard session.startedAt >= weekStart, session.startedAt < weekEnd else { continue }
                for we in session.workoutExercises {
                    let part = we.exercise?.bodyPartTag.isEmpty == false ? we.exercise!.bodyPartTag : "その他"
                    let vol = totalVolume(for: we)
                    if vol > 0 {
                        result.append((weekStart, part, vol))
                    }
                }
            }
        }
        var aggregated: [String: [Date: Double]] = [:]
        for (weekStart, part, vol) in result {
            aggregated[part, default: [:]][weekStart, default: 0] += vol
        }
        var flat: [(Date, String, Double)] = []
        for (part, weekToVol) in aggregated {
            for (weekStart, vol) in weekToVol {
                flat.append((weekStart, part, vol))
            }
        }
        return flat.sorted { $0.0 < $1.0 }
    }

    /// 週別セッション数（直近 weekCount 週）。各週の開始日と完了セッション数を昇順で返す。継続セクションの円グラフ用。
    func weeklySessionCounts(weekCount: Int = 12) throws -> [(weekStart: Date, count: Int)] {
        let cal = Calendar.current
        let now = Date()
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        guard let rangeStart = cal.date(byAdding: .weekOfYear, value: -(weekCount + 1), to: thisWeekStart) else {
            return []
        }
        let rangeStartBound = rangeStart
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= rangeStartBound
            }
        )
        let sessions = try modelContext.fetch(descriptor)
        var weekToCount: [Date: Int] = [:]
        for session in sessions {
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.startedAt)) ?? session.startedAt
            weekToCount[weekStart, default: 0] += 1
        }
        var result: [(Date, Int)] = []
        for weekOffset in 0..<weekCount {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: thisWeekStart) else { continue }
            result.append((weekStart, weekToCount[weekStart] ?? 0))
        }
        return result.sorted { $0.0 < $1.0 }
    }

    /// 週ごとの総挙上（直近 weekCount 週）。各週はカレンダー週の開始〜7日未満の完了セッションを集計。
    func weeklyTotalVolumes(weekCount: Int = 12) throws -> [(weekStart: Date, volume: Double)] {
        let cal = Calendar.current
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        guard let rangeStart = cal.date(byAdding: .weekOfYear, value: -(weekCount + 1), to: thisWeekStart) else {
            return []
        }
        let rangeStartBound = rangeStart
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= rangeStartBound
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)
        var result: [(Date, Double)] = []
        for weekOffset in 0..<weekCount {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: thisWeekStart),
                  let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            var vol: Double = 0
            for session in sessions {
                guard session.startedAt >= weekStart, session.startedAt < weekEnd else { continue }
                vol += totalVolume(for: session)
            }
            result.append((weekStart, vol))
        }
        return result.sorted { $0.0 < $1.0 }
    }

    /// 連続実施週数（今週から過去に何週連続で1回以上実施したか）
    func currentStreakWeeks() throws -> Int {
        let cal = Calendar.current
        let now = Date()
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return 0 }
        let repo = WorkoutRepository(modelContext: modelContext)
        var weekToCount: [Date: Int] = [:]
        var before: Date? = nil
        let pageSize = 200
        while true {
            let batch = try repo.fetchRecentSessions(limit: pageSize, before: before)
            if batch.isEmpty { break }
            for session in batch {
                let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.startedAt)) ?? session.startedAt
                weekToCount[weekStart, default: 0] += 1
            }
            if batch.count < pageSize { break }
            before = batch.last?.startedAt
        }
        var streak = 0
        var cursor = thisWeekStart
        while (weekToCount[cursor] ?? 0) > 0 {
            streak += 1
            guard let next = cal.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = next
        }
        return streak
    }

    /// 直近 `days` 日分（今日を含む）の総挙上 kg。カレンダー日の開始から現在まで。
    func totalVolumeRollingDays(_ days: Int) throws -> Double {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        guard let start = cal.date(byAdding: .day, value: -(days - 1), to: startOfToday) else { return 0 }
        return try totalVolume(from: start, to: now)
    }

    /// 表示中のカレンダー月に含まれる完了セッション件数（`startedAt` がその月の範囲内）。
    func completedSessionCount(inMonthContaining monthAnchor: Date) throws -> Int {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)),
              let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { return 0 }
        let sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: monthStart, to: nextMonth)
        return sessions.count
    }

    /// 指定月の各「日」に完了セッションが1件以上あるか（1...31 の Set）。
    func completedSessionDaysOfMonth(containing monthAnchor: Date) throws -> Set<Int> {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)),
              let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { return [] }
        let repo = WorkoutRepository(modelContext: modelContext)
        let sessions = try repo.fetchSessions(from: monthStart, to: nextMonth)
        var days = Set<Int>()
        for s in sessions {
            let d = cal.component(.day, from: s.startedAt)
            days.insert(d)
        }
        return days
    }

    /// 1セッションの総セット数（保存順）。
    func sessionTotalSetCount(session: WorkoutSession) -> Int {
        session.workoutExercises.reduce(0) { $0 + $1.sets.count }
    }

    /// 1セッションの総レップ数（nilは0）。
    func sessionTotalRepCount(session: WorkoutSession) -> Int {
        session.workoutExercises.reduce(0) { sum, exercise in
            sum + exercise.sets.reduce(0) { $0 + max(0, $1.reps ?? 0) }
        }
    }

    /// 1セッションの種目数。
    func sessionExerciseCount(session: WorkoutSession) -> Int {
        session.workoutExercises.count
    }

    /// 直近N日で実施したユニーク日数（今日を含む）。
    func trainingDaysCount(lastDays: Int) throws -> Int {
        guard lastDays > 0 else { return 0 }
        let cal = Calendar.current
        let now = Date()
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
        let start = cal.date(byAdding: .day, value: -(lastDays - 1), to: cal.startOfDay(for: now)) ?? now
        let sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: start, to: end)
        var days = Set<Date>()
        for session in sessions {
            days.insert(cal.startOfDay(for: session.startedAt))
        }
        return days.count
    }

    /// 平均ワークアウト時間（秒）。完了セッションのみ。
    func averageSessionDuration(range: (start: Date, end: Date)? = nil) throws -> Double {
        let sessions: [WorkoutSession]
        if let range {
            sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: range.start, to: range.end)
        } else {
            sessions = try WorkoutRepository(modelContext: modelContext).fetchRecentSessions(limit: 1000, before: nil)
        }
        let durations = sessions.compactMap(\.durationSeconds).filter { $0 > 0 }
        guard !durations.isEmpty else { return 0 }
        return Double(durations.reduce(0, +)) / Double(durations.count)
    }

    /// 平均セット数（完了セッション1件あたり）。
    func averageSetCountPerSession(range: (start: Date, end: Date)? = nil) throws -> Double {
        let sessions: [WorkoutSession]
        if let range {
            sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: range.start, to: range.end)
        } else {
            sessions = try WorkoutRepository(modelContext: modelContext).fetchRecentSessions(limit: 1000, before: nil)
        }
        guard !sessions.isEmpty else { return 0 }
        let totalSets = sessions.reduce(0) { $0 + sessionTotalSetCount(session: $1) }
        return Double(totalSets) / Double(sessions.count)
    }

    /// 平均種目数（完了セッション1件あたり）。
    func averageExerciseCountPerSession(range: (start: Date, end: Date)? = nil) throws -> Double {
        let sessions: [WorkoutSession]
        if let range {
            sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: range.start, to: range.end)
        } else {
            sessions = try WorkoutRepository(modelContext: modelContext).fetchRecentSessions(limit: 1000, before: nil)
        }
        guard !sessions.isEmpty else { return 0 }
        let totalExercises = sessions.reduce(0) { $0 + sessionExerciseCount(session: $1) }
        return Double(totalExercises) / Double(sessions.count)
    }

    /// 月ごとの総挙上（直近 monthCount ヶ月）。月間ボリューム比較グラフ用。
    func monthlyVolumes(monthCount: Int = 6) throws -> [(monthStart: Date, volume: Double)] {
        let cal = Calendar.current
        let now = Date()
        guard let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return [] }
        var result: [(Date, Double)] = []
        for monthOffset in 0..<monthCount {
            guard let monthStart = cal.date(byAdding: .month, value: -monthOffset, to: thisMonthStart),
                  let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let vol = try totalVolume(from: monthStart, to: monthEnd)
            result.append((monthStart, vol))
        }
        return result.sorted { $0.0 < $1.0 }
    }

    /// 部位別の週次セッション数。各週について、少なくとも1種目がその部位を含む完了セッションを数える。
    func weeklySessionCountsForBodyPart(_ bodyPart: String, weekCount: Int = 12) throws -> [(weekStart: Date, count: Int)] {
        let cal = Calendar.current
        let now = Date()
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let rangeStart = cal.date(byAdding: .weekOfYear, value: -(weekCount + 1), to: thisWeekStart) else { return [] }
        let rangeStartBound = rangeStart
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= rangeStartBound
            }
        )
        let sessions = try modelContext.fetch(descriptor)
        var weekToCount: [Date: Int] = [:]
        for session in sessions {
            let hasPart = session.workoutExercises.contains { $0.exercise?.bodyPartTag == bodyPart }
            guard hasPart else { continue }
            let ws = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.startedAt)) ?? session.startedAt
            weekToCount[ws, default: 0] += 1
        }
        var result: [(Date, Int)] = []
        for weekOffset in 0..<weekCount {
            guard let ws = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: thisWeekStart) else { continue }
            result.append((ws, weekToCount[ws] ?? 0))
        }
        return result.sorted { $0.0 < $1.0 }
    }

    /// 全 PR を一括取得して exerciseId → PersonalRecord の辞書にする（N+1 回避）。
    func fetchAllPRsAsMap(modelContext: ModelContext) throws -> [UUID: PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>()
        let all = try modelContext.fetch(descriptor)
        var map: [UUID: PersonalRecord] = [:]
        for pr in all { map[pr.exerciseId] = pr }
        return map
    }

    /// 日ごとのセッション数（直近 weekCount 週）。キーは Calendar.startOfDay。ヒートマップ用。
    func dailySessionCounts(weekCount: Int = 12) throws -> [Date: Int] {
        let cal = Calendar.current
        let now = Date()
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let rangeStart = cal.date(byAdding: .weekOfYear, value: -weekCount, to: thisWeekStart) else { return [:] }
        let rangeStartBound = rangeStart
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= rangeStartBound
            }
        )
        let sessions = try modelContext.fetch(descriptor)
        var result: [Date: Int] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.startedAt)
            result[day, default: 0] += 1
        }
        return result
    }
}
