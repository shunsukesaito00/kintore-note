// App Store 申請用のスクショ向けデモデータ。ON で投入・OFF で削除（本体データは UserDefaults にバックアップして復元）。

import Foundation
import SwiftData

enum AppStoreScreenshotDemoData {

    private static let enabledKey = "kintore.appStoreDemoData.enabled"
    private static let sessionIdsKey = "kintore.appStoreDemoData.sessionIds"
    private static let prTouchedExerciseIdsKey = "kintore.appStoreDemoData.prTouchedExerciseIds"
    private static let prBackupDataKey = "kintore.appStoreDemoData.prBackupData"
    private static let weeklyGoalBackupKey = "kintore.appStoreDemoData.weeklyGoalBackup"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// 設定トグル ON。既存デモを消してから再シード（常に同じ手順でクリーンに撮れる）。
    static func turnOn(modelContext: ModelContext) throws {
        if !storedSessionIds().isEmpty {
            try removeDemoSessionsAndRestorePRs(modelContext: modelContext)
        }
        backupWeeklyGoalIfNeeded(modelContext: modelContext)
        try seed(modelContext: modelContext)
        applyDemoWeeklyGoal(modelContext: modelContext)
        isEnabled = true
        WidgetDataStore.updateFrom(modelContext: modelContext)
    }

    /// 設定トグル OFF。デモセッション削除＋PR 復元＋週目標復元。
    static func turnOff(modelContext: ModelContext) throws {
        try removeDemoSessionsAndRestorePRs(modelContext: modelContext)
        restoreWeeklyGoal(modelContext: modelContext)
        isEnabled = false
        clearStoredIds()
        WidgetDataStore.updateFrom(modelContext: modelContext)
    }

    // MARK: - Seed

    private static func seed(modelContext: ModelContext) throws {
        let exRepo = ExerciseRepository(modelContext: modelContext)
        let all = try exRepo.fetchAllExercises()
        func ex(_ name: String) throws -> Exercise {
            guard let e = all.first(where: { $0.name == name }) else {
                throw NSError(domain: "AppStoreScreenshotDemoData", code: 1, userInfo: [NSLocalizedDescriptionKey: "種目が見つかりません: \(name)"])
            }
            return e
        }

        let bench = try ex("ベンチプレス")
        let incline = try ex("インクラインベンチプレス")
        let squat = try ex("スクワット")
        let legPress = try ex("レッグプレス")
        let deadlift = try ex("デッドリフト")
        let lat = try ex("ラットプルダウン")
        let row = try ex("シーテッドロー")
        let ohp = try ex("ショルダープレス")
        let curl = try ex("アームカール")
        let pushdown = try ex("トライセプスプレスダウン")

        try backupPRsBeforeOverwrite(modelContext: modelContext, exerciseIds: [
            bench.id, squat.id, deadlift.id, lat.id
        ])

        var newSessionIds: [UUID] = []

        /// daysAgo: 今日が 0。startedAt はその日の 18:30 頃。
        func addSession(daysAgo: Int, durationMin: Int, blocks: [(Exercise, [(Double, Int)])]) throws {
            let cal = Calendar.current
            let base = cal.startOfDay(for: Date())
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: base) else { return }
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = 18
            comps.minute = 32
            let started = cal.date(from: comps) ?? day.addingTimeInterval(18 * 3600 + 32 * 60)
            let ended = started.addingTimeInterval(TimeInterval(durationMin * 60))
            let session = WorkoutSession(
                startedAt: started,
                endedAt: ended,
                durationSeconds: durationMin * 60
            )
            modelContext.insert(session)
            for (idx, block) in blocks.enumerated() {
                let (exercise, sets) = block
                let we = WorkoutExercise(orderIndex: idx, session: session, exercise: exercise)
                modelContext.insert(we)
                for (i, s) in sets.enumerated() {
                    let t = ended.addingTimeInterval(-Double(sets.count - i) * 45)
                    let ws = WorkoutSet(
                        weight: s.0,
                        reps: s.1,
                        orderIndex: i,
                        completedAt: t,
                        workoutExercise: we
                    )
                    modelContext.insert(ws)
                }
            }
            newSessionIds.append(session.id)
        }

        let daysAgoList = [2, 4, 7, 9, 11, 14, 16, 18, 21, 23, 25, 28, 30, 32, 35, 37, 39, 42, 44, 46, 49, 51, 53, 56, 58, 61, 63, 66, 68, 70]
        let templates: [[(Exercise, [(Double, Int)])]] = [
            // Push
            [
                (bench, [(60, 12), (70, 10), (75, 8), (75, 8)]),
                (incline, [(50, 10), (55, 8), (55, 8)]),
                (ohp, [(40, 10), (45, 8), (45, 8)]),
                (pushdown, [(25, 12), (27.5, 10), (27.5, 10)])
            ],
            // Pull
            [
                (deadlift, [(100, 8), (110, 6), (120, 5)]),
                (lat, [(45, 12), (50, 10), (52.5, 8)]),
                (row, [(50, 10), (55, 10), (55, 8)]),
                (curl, [(12, 12), (14, 10), (14, 10)])
            ],
            // Legs
            [
                (squat, [(80, 10), (90, 8), (100, 6), (100, 6)]),
                (legPress, [(140, 12), (160, 10), (180, 8)]),
                (bench, [(60, 10), (65, 8)])
            ]
        ]

        for (i, daysAgo) in daysAgoList.enumerated() {
            let t = templates[i % templates.count]
            let weeksFactor = 1.0 - (Double(daysAgo) / 75.0) * 0.14
            let scaled: [(Exercise, [(Double, Int)])] = t.map { ex, sets in
                (ex, sets.map { (($0.0 * weeksFactor).rounded(to: 2.5), $0.1) })
            }
            try addSession(daysAgo: daysAgo, durationMin: 55 + (i % 5) * 4, blocks: scaled)
        }

        try modelContext.save()

        let prService = PersonalRecordService(modelContext: modelContext)
        let cal = Calendar.current
        let prDate = cal.startOfDay(for: Date()).addingTimeInterval(20 * 3600)

        try prService.updateIfNeeded(exerciseId: bench.id, weight: 77.5, reps: 8, achievedAt: prDate.addingTimeInterval(-86400 * 2))
        try prService.updateIfNeeded(exerciseId: squat.id, weight: 102.5, reps: 6, achievedAt: prDate.addingTimeInterval(-86400 * 4))
        try prService.updateIfNeeded(exerciseId: deadlift.id, weight: 125, reps: 5, achievedAt: prDate.addingTimeInterval(-86400 * 3))
        try prService.updateIfNeeded(exerciseId: lat.id, weight: 55, reps: 10, achievedAt: prDate.addingTimeInterval(-86400 * 5))

        storeSessionIds(newSessionIds)
        markPRsTouched(exerciseIds: [bench.id, squat.id, deadlift.id, lat.id])
        try modelContext.save()
    }

    private static func backupWeeklyGoalIfNeeded(modelContext: ModelContext) {
        guard UserDefaults.standard.object(forKey: weeklyGoalBackupKey) == nil else { return }
        let repo = SettingsRepository(modelContext: modelContext)
        guard let pref = try? repo.fetchUserPreference() else { return }
        UserDefaults.standard.set(pref.weeklyWorkoutGoalSessions, forKey: weeklyGoalBackupKey)
    }

    private static func applyDemoWeeklyGoal(modelContext: ModelContext) {
        let repo = SettingsRepository(modelContext: modelContext)
        try? repo.updateWeeklyWorkoutGoalSessions(5)
        try? modelContext.save()
    }

    private static func restoreWeeklyGoal(modelContext: ModelContext) {
        let repo = SettingsRepository(modelContext: modelContext)
        let backup = UserDefaults.standard.object(forKey: weeklyGoalBackupKey) as? Int ?? 0
        try? repo.updateWeeklyWorkoutGoalSessions(backup)
        UserDefaults.standard.removeObject(forKey: weeklyGoalBackupKey)
        try? modelContext.save()
    }

    // MARK: - PR backup / restore

    private struct PRBackup: Codable {
        var id: UUID
        var weight: Double
        var reps: Int
        var volume: Double
        var achievedAt: Date
    }

    private static func backupPRsBeforeOverwrite(modelContext: ModelContext, exerciseIds: [UUID]) throws {
        let prService = PersonalRecordService(modelContext: modelContext)
        var dict: [String: PRBackup] = [:]
        for eid in exerciseIds {
            if let pr = try? prService.fetchPersonalRecord(exerciseId: eid) {
                dict[eid.uuidString] = PRBackup(
                    id: pr.id,
                    weight: pr.weight,
                    reps: pr.reps,
                    volume: pr.volume,
                    achievedAt: pr.achievedAt
                )
            }
        }
        let data = try JSONEncoder().encode(dict)
        UserDefaults.standard.set(data, forKey: prBackupDataKey)
    }

    private static func restorePRsFromBackup(modelContext: ModelContext) throws {
        let touched = storedPRTouchedExerciseIds()
        guard let data = UserDefaults.standard.data(forKey: prBackupDataKey) else {
            try deletePRsForTouchedExercises(modelContext: modelContext)
            return
        }
        let decoded = try JSONDecoder().decode([String: PRBackup].self, from: data)

        for eidStr in touched {
            guard let eid = UUID(uuidString: eidStr) else { continue }
            var descriptor = FetchDescriptor<PersonalRecord>(
                predicate: #Predicate<PersonalRecord> { $0.exerciseId == eid }
            )
            descriptor.fetchLimit = 1
            if let row = try modelContext.fetch(descriptor).first {
                modelContext.delete(row)
            }
            if let backup = decoded[eidStr] {
                let pr = PersonalRecord(
                    id: backup.id,
                    exerciseId: eid,
                    weight: backup.weight,
                    reps: backup.reps,
                    volume: backup.volume,
                    achievedAt: backup.achievedAt
                )
                modelContext.insert(pr)
            }
        }
        UserDefaults.standard.removeObject(forKey: prBackupDataKey)
    }

    private static func deletePRsForTouchedExercises(modelContext: ModelContext) throws {
        for eidStr in storedPRTouchedExerciseIds() {
            guard let eid = UUID(uuidString: eidStr) else { continue }
            var descriptor = FetchDescriptor<PersonalRecord>(
                predicate: #Predicate<PersonalRecord> { $0.exerciseId == eid }
            )
            descriptor.fetchLimit = 1
            if let row = try modelContext.fetch(descriptor).first {
                modelContext.delete(row)
            }
        }
    }

    private static func markPRsTouched(exerciseIds: [UUID]) {
        UserDefaults.standard.set(exerciseIds.map(\.uuidString), forKey: prTouchedExerciseIdsKey)
    }

    private static func storedPRTouchedExerciseIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: prTouchedExerciseIdsKey) ?? []
    }

    // MARK: - Remove sessions

    private static func removeDemoSessionsAndRestorePRs(modelContext: ModelContext) throws {
        let repo = WorkoutRepository(modelContext: modelContext)
        for id in storedSessionIds() {
            if let s = try repo.fetchSession(by: id) {
                try repo.deleteSession(s)
            }
        }
        try restorePRsFromBackup(modelContext: modelContext)
        UserDefaults.standard.removeObject(forKey: prTouchedExerciseIdsKey)
        try modelContext.save()
    }

    private static func storedSessionIds() -> [UUID] {
        (UserDefaults.standard.stringArray(forKey: sessionIdsKey) ?? []).compactMap(UUID.init(uuidString:))
    }

    private static func storeSessionIds(_ ids: [UUID]) {
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: sessionIdsKey)
    }

    private static func clearStoredIds() {
        UserDefaults.standard.removeObject(forKey: sessionIdsKey)
    }
}

private extension Double {
    func rounded(to step: Double) -> Double {
        (self / step).rounded() * step
    }
}
