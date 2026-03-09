// File: App/KintoreApp.swift
// Phase 1: SwiftData コンテナと初回起動 Seed の接続用。UI は Phase 2 以降で実装。

import SwiftUI
import SwiftData

@main
struct KintoreApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainerFactory.makeProduction()
            let context = ModelContext(container)
            AppBootstrapper.runIfNeeded(modelContext: context)
        } catch {
            fatalError("ModelContainer の作成に失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(container)
        }
    }
}
