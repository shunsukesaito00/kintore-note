// File: Modules/History/SessionDetailView.swift

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let sessionId: UUID

    @State private var session: WorkoutSession?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let session = session {
                sessionContent(session: session)
            } else if loadError != nil {
                Text(loadError ?? "")
                    .foregroundStyle(.red)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("セッション詳細")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSession() }
    }

    private func loadSession() {
        do {
            session = try WorkoutRepository(modelContext: modelContext).fetchSession(by: sessionId)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func sessionContent(session: WorkoutSession) -> some View {
        let stats = WorkoutStatsService(modelContext: modelContext)
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppFormatters.formatDateWithWeekday(session.startedAt))
                            .font(.headline)
                        HStack {
                            if let d = session.durationSeconds {
                                MetricChip(text: AppFormatters.formatDuration(seconds: d))
                            }
                            MetricChip(text: "\(Int(stats.totalVolume(for: session)))kg 挙上")
                        }
                    }
                }
                ForEach(exercises, id: \.id) { we in
                    exerciseBlock(workoutExercise: we, stats: stats)
                }
            }
            .padding()
        }
    }

    private func exerciseBlock(workoutExercise: WorkoutExercise, stats: WorkoutStatsService) -> some View {
        let sets = workoutExercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        return SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(workoutExercise.exercise?.name ?? "種目")
                    .font(.headline)
                Text("\(Int(stats.totalVolume(for: workoutExercise)))kg 挙上")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(sets, id: \.id) { set in
                    HStack {
                        Text("セット\(set.orderIndex + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(AppFormatters.formatWeight(set.weight))
                        Text("× \(set.reps ?? 0)回")
                    }
                    .font(.subheadline)
                }
                if let memo = workoutExercise.freeMemo, !memo.isEmpty {
                    Text(memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(sessionId: UUID())
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, WorkoutSet.self, Exercise.self], inMemory: true)
}
