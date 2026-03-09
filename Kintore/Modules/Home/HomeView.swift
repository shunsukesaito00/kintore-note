// File: Modules/Home/HomeView.swift

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showWorkoutStart = false

    var body: some View {
        let vm = viewModel ?? HomeViewModel(workoutRepository: WorkoutRepository(modelContext: modelContext))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PrimaryButton(title: "今日のワークアウトを記録") {
                        showWorkoutStart = true
                    }
                    .onAppear { if viewModel == nil { viewModel = vm; vm.loadRecentSessions() } }

                    Button("前回のルーティンで続ける") {
                        showWorkoutStart = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("直近の履歴")
                            .font(.headline)
                        if vm.recentSessions.isEmpty && !vm.isLoading {
                            EmptyStateView(message: "まだ履歴がありません")
                        } else {
                            ForEach(vm.recentSessions, id: \.id) { session in
                                SessionRowView(session: session)
                            }
                        }
                    }

                    NavigationLink("履歴をもっと見る", destination: HistoryListView())
                        .font(.subheadline)
                }
                .padding()
            }
            .navigationTitle("RepLog")
            .fullScreenCover(isPresented: $showWorkoutStart) {
                WorkoutStartView(onDismiss: {
                    showWorkoutStart = false
                    vm.loadRecentSessions()
                })
                .environment(\.modelContext, modelContext)
            }
            .navigationDestination(for: UUID.self) { sessionId in
                SessionDetailView(sessionId: sessionId)
            }
        }
        .onAppear {
            if viewModel == nil { viewModel = vm }
            vm.loadRecentSessions()
        }
    }
}

private struct SessionRowView: View {
    let session: WorkoutSession

    var body: some View {
        NavigationLink(value: session.id) {
            SectionCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppFormatters.formatDateWithWeekday(session.startedAt))
                        .font(.subheadline)
                    HStack {
                        MetricChip(text: "\(session.workoutExercises.count)種目")
                        if let d = session.durationSeconds {
                            MetricChip(text: AppFormatters.formatDuration(seconds: d))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self], inMemory: true)
}
