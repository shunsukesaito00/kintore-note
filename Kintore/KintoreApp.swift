// File: App/KintoreApp.swift
// Phase 1: SwiftData コンテナと初回起動 Seed の接続用。UI は Phase 2 以降で実装。

import SwiftUI
import SwiftData
#if os(iOS)
import GoogleMobileAds
#endif

private let usedInMemoryStoreUserDefaultsKey = "kintore.bootstrap.inMemoryStoreDueToLoadFailure"

enum AppModelBootstrap {
    static var usedInMemoryStoreDueToLoadFailure: Bool {
        UserDefaults.standard.bool(forKey: usedInMemoryStoreUserDefaultsKey)
    }

    static func markUsedInMemoryStoreFallback() {
        UserDefaults.standard.set(true, forKey: usedInMemoryStoreUserDefaultsKey)
    }
}

@main
struct KintoreApp: App {
    let container: ModelContainer

    init() {
        ModelContainerFactory.performPendingPersistentStoreEraseIfNeeded()
        do {
            container = try ModelContainerFactory.makeProduction()
            UserDefaults.standard.set(false, forKey: usedInMemoryStoreUserDefaultsKey)
            let context = ModelContext(container)
            TreadmillCardioExercisesSeed.upsertIfNeeded(modelContext: context)
            DefaultExercisesSeed.upsertMissingPresets(modelContext: context)
            AppBootstrapper.runIfNeeded(modelContext: context)
            try? AppStoreScreenshotDemoData.runLegacyCleanupIfNeeded(modelContext: context)
            #if os(iOS)
            performIOSStartupSideEffects(modelContext: context)
            #endif
        } catch {
            // makeProduction 内でも記録済み。ここではフォールバックのみ。
            #if DEBUG
            print("[KintoreApp] persistent ModelContainer failed: \(error). Falling back to in-memory store.")
            #endif
            do {
                container = try ModelContainerFactory.makeInMemory()
                AppModelBootstrap.markUsedInMemoryStoreFallback()
                let context = ModelContext(container)
                TreadmillCardioExercisesSeed.upsertIfNeeded(modelContext: context)
                DefaultExercisesSeed.upsertMissingPresets(modelContext: context)
                AppBootstrapper.runIfNeeded(modelContext: context)
                try? AppStoreScreenshotDemoData.runLegacyCleanupIfNeeded(modelContext: context)
                #if os(iOS)
                performIOSStartupSideEffects(modelContext: context)
                #endif
            } catch {
                fatalError("ModelContainer の作成に失敗: \(error)")
            }
        }
    }

    #if os(iOS)
    private func performIOSStartupSideEffects(modelContext: ModelContext) {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "kintore.hasLaunchedBefore")
        if isFirstLaunch { UserDefaults.standard.set(true, forKey: "kintore.hasLaunchedBefore") }
        AnalyticsEventService.log(.appLaunch(isFirstLaunch: isFirstLaunch))
        WatchSyncManager.shared.activate()
        RetentionNotificationService.syncWeeklySummarySchedule(modelContext: modelContext)
        Task {
            await PremiumService.shared.refresh()
        }
        MobileAds.shared.start(completionHandler: nil)
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                #if os(iOS)
                .onOpenURL { url in
                    AppDeepLinkHandler.apply(url)
                    AnalyticsEventService.log(.deepLinkOpened(url: url))
                }
                #endif
        }
    }
}
