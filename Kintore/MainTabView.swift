// File: App/MainTabView.swift

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: UUID.self) { sessionId in
                        SessionDetailView(sessionId: sessionId)
                    }
            }
            .tabItem {
                Label("ホーム", systemImage: "house")
            }
            NavigationStack {
                HistoryListView()
                    .navigationDestination(for: UUID.self) { sessionId in
                        SessionDetailView(sessionId: sessionId)
                    }
            }
            .tabItem {
                Label("履歴", systemImage: "list.bullet.clipboard")
            }
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("統計", systemImage: "chart.bar")
            }
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
