// File: KintoreWatch/KintoreWatchApp.swift

import SwiftUI

@main
struct KintoreWatchApp: App {
    init() {
        WatchSessionManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
