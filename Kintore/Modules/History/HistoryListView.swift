// File: Modules/History/HistoryListView.swift

import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryListViewModel?

    var body: some View {
        let vm = viewModel ?? HistoryListViewModel(workoutRepository: WorkoutRepository(modelContext: modelContext))
        Group {
            if vm.sessions.isEmpty && !vm.isLoading {
                EmptyStateView(message: "まだ履歴がありません")
            } else {
                List {
                    ForEach(vm.sessions, id: \.id) { session in
                        NavigationLink(value: session.id) {
                            HistoryRowView(session: session)
                        }
                    }
                }
            }
        }
        .navigationTitle("履歴")
        .onAppear {
            if viewModel == nil { viewModel = vm }
            vm.load()
        }
    }
}

private struct HistoryRowView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession

    var body: some View {
        let stats = WorkoutStatsService(modelContext: modelContext)
        VStack(alignment: .leading, spacing: 4) {
            Text(AppFormatters.formatDateWithWeekday(session.startedAt))
                .font(.subheadline)
            HStack {
                MetricChip(text: "\(session.workoutExercises.count)種目")
                if let d = session.durationSeconds {
                    MetricChip(text: AppFormatters.formatDuration(seconds: d))
                }
                MetricChip(text: "\(Int(stats.totalVolume(for: session)))kg 挙上")
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HistoryListView()
    }
    .modelContainer(for: [WorkoutSession.self], inMemory: true)
}
