// File: Core/Seed/AppBootstrapper.swift
// 初回起動時に UserPreference を作成。種目プリセットは `KintoreApp` 側で毎回 upsert。

import Foundation
import SwiftData

enum AppBootstrapper {

    private static let didBootstrapKey = "AppBootstrapper.didBootstrap"

    /// アプリ起動時に 1 回呼ぶ。UserDefaults で二重実行を防ぐ。
    static func runIfNeeded(modelContext: ModelContext) {
        if UserDefaults.standard.bool(forKey: didBootstrapKey) { return }

        // 1. UserPreference を 1 件作成（既存がなければ）
        createUserPreferenceIfNeeded(modelContext: modelContext)

        UserDefaults.standard.set(true, forKey: didBootstrapKey)
        try? modelContext.save()
    }

    private static func createUserPreferenceIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserPreference>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if !existing.isEmpty { return }

        let pref = UserPreference(
            defaultRestSeconds: 90,
            weightUnit: "kg",
            theme: "system",
            weeklyWorkoutGoalSessions: 0,
            monthlyWorkoutGoalSessions: 0
        )
        modelContext.insert(pref)
        try? modelContext.save()
        UserDefaults.standard.set(pref.weightUnit, forKey: AppTheme.weightUnitStorageKey)
    }
}
