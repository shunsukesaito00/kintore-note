// File: Modules/Statistics/StatisticsView.swift

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sessionCount: Int = 0
    @State private var totalVolume: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ワークアウト回数")
                            .font(.headline)
                        Text("\(sessionCount) 回")
                            .font(.title2)
                    }
                }
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("総挙上重量")
                            .font(.headline)
                        Text("\(Int(totalVolume)) kg")
                            .font(.title2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("統計")
        .onAppear { loadStats() }
    }

    private func loadStats() {
        do {
            let repo = WorkoutRepository(modelContext: modelContext)
            let sessions = try repo.fetchRecentSessions(limit: 1000)
            sessionCount = sessions.filter { $0.endedAt != nil }.count
            let stats = WorkoutStatsService(modelContext: modelContext)
            totalVolume = sessions.filter { $0.endedAt != nil }.reduce(0) { $0 + stats.totalVolume(for: $1) }
        } catch {
            sessionCount = 0
            totalVolume = 0
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
