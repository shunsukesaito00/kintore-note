// 旧「App Store スクショ用デモデータ」設定の残骸を 1 回限りで除去する（設定 UI は削除済み）。

import Foundation
import SwiftData

enum AppStoreScreenshotDemoData {

    private static let enabledKey = "kintore.appStoreDemoData.enabled"
    private static let sessionIdsKey = "kintore.appStoreDemoData.sessionIds"
    private static let prTouchedExerciseIdsKey = "kintore.appStoreDemoData.prTouchedExerciseIds"
    private static let prBackupDataKey = "kintore.appStoreDemoData.prBackupData"
    private static let weeklyGoalBackupKey = "kintore.appStoreDemoData.weeklyGoalBackup"

    /// デモ用 UserDefaults またはデモセッションが残っていれば削除し、PR・週目標を復元する。
    static func runLegacyCleanupIfNeeded(modelContext: ModelContext) throws {
        guard legacyArtifactsPresent() else { return }
        try removeDemoSessionsAndRestorePRs(modelContext: modelContext)
        restoreWeeklyGoal(modelContext: modelContext)
        UserDefaults.standard.set(false, forKey: enabledKey)
        clearStoredIds()
        WidgetDataStore.updateFrom(modelContext: modelContext)
        try modelContext.save()
    }

    private static func legacyArtifactsPresent() -> Bool {
        let ud = UserDefaults.standard
        if ud.bool(forKey: enabledKey) { return true }
        if !(ud.stringArray(forKey: sessionIdsKey) ?? []).isEmpty { return true }
        if ud.data(forKey: prBackupDataKey) != nil { return true }
        if ud.object(forKey: weeklyGoalBackupKey) != nil { return true }
        if !(ud.stringArray(forKey: prTouchedExerciseIdsKey) ?? []).isEmpty { return true }
        return false
    }

    // MARK: - PR backup / restore

    private struct PRBackup: Codable {
        var id: UUID
        var weight: Double
        var reps: Int
        var volume: Double
        var achievedAt: Date
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

    private static func storedPRTouchedExerciseIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: prTouchedExerciseIdsKey) ?? []
    }

    private static func removeDemoSessionsAndRestorePRs(modelContext: ModelContext) throws {
        let repo = WorkoutRepository(modelContext: modelContext)
        for id in storedSessionIds() {
            if let s = try repo.fetchSession(by: id) {
                try repo.deleteSession(s)
            }
        }
        try restorePRsFromBackup(modelContext: modelContext)
        UserDefaults.standard.removeObject(forKey: prTouchedExerciseIdsKey)
    }

    private static func storedSessionIds() -> [UUID] {
        (UserDefaults.standard.stringArray(forKey: sessionIdsKey) ?? []).compactMap(UUID.init(uuidString:))
    }

    private static func clearStoredIds() {
        UserDefaults.standard.removeObject(forKey: sessionIdsKey)
    }

    private static func restoreWeeklyGoal(modelContext: ModelContext) {
        let repo = SettingsRepository(modelContext: modelContext)
        let backup = UserDefaults.standard.object(forKey: weeklyGoalBackupKey) as? Int ?? 0
        try? repo.updateWeeklyWorkoutGoalSessions(backup)
        UserDefaults.standard.removeObject(forKey: weeklyGoalBackupKey)
        try? modelContext.save()
    }
}
