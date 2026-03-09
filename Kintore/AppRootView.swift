// File: App/AppRootView.swift

import SwiftUI
import SwiftData

struct AppRootView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self], inMemory: true)
}
