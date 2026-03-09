// File: Core/Seed/AppBootstrapper.swift
// 初回起動時に UserPreference 作成・種目 Seed・メモタグ Seed を実行。二重投入防止は各 Seed 内で実施。

import Foundation
import SwiftData

enum AppBootstrapper {

    private static let didBootstrapKey = "AppBootstrapper.didBootstrap"

    /// アプリ起動時に 1 回呼ぶ。UserDefaults で二重実行を防ぐ。
    static func runIfNeeded(modelContext: ModelContext) {
        if UserDefaults.standard.bool(forKey: didBootstrapKey) { return }

        // 1. UserPreference を 1 件作成（既存がなければ）
        createUserPreferenceIfNeeded(modelContext: modelContext)

        // 2. 種目・メモタグの Seed（各 Seed 内で既存チェック）
        DefaultExercisesSeed.seedIfNeeded(modelContext: modelContext)
        DefaultMemoTagsSeed.seedIfNeeded(modelContext: modelContext)

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
            theme: "system"
        )
        modelContext.insert(pref)
        try? modelContext.save()
    }
}
