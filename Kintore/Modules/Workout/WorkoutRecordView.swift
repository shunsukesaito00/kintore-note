// File: Modules/Workout/WorkoutRecordView.swift

import SwiftUI
import SwiftData
import UIKit

struct WorkoutRecordView: View {
    @Environment(\.modelContext) private var modelContext
    let draft: WorkoutSessionDraft
    let onDismiss: () -> Void

    @State private var viewModel: WorkoutRecordViewModel?
    @State private var showExercisePicker = false
    @State private var showEndConfirm = false
    @State private var restTimer = RestTimerManager()

    var body: some View {
        let vm: WorkoutRecordViewModel = {
            if let v = viewModel { return v }
            let w = WorkoutRepository(modelContext: modelContext)
            let e = ExerciseRepository(modelContext: modelContext)
            let prev = PreviousRecordService(workoutRepository: w)
            let pr = PersonalRecordService(modelContext: modelContext)
            let memoTagRepo = MemoTagRepository(modelContext: modelContext)
            let settings = SettingsRepository(modelContext: modelContext)
            let v = WorkoutRecordViewModel(
                draft: draft,
                workoutRepository: w,
                exerciseRepository: e,
                previousRecordService: prev,
                personalRecordService: pr,
                memoTagRepository: memoTagRepo,
                settingsRepository: settings,
                restTimerManager: restTimer,
                modelContext: modelContext
            )
            v.onSaveSuccess = onDismiss
            return v
        }()
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sessionHeader(startedAt: vm.draft.startedAt)

                    if restTimer.isResting {
                        restTimerCard(restTimer: restTimer)
                    }

                    Button("種目を追加") {
                        showExercisePicker = true
                    }
                    .buttonStyle(.bordered)

                    ForEach(Array(vm.draft.exercises.enumerated()), id: \.element.id) { exerciseIndex, exerciseDraft in
                        exerciseCard(viewModel: vm, exerciseIndex: exerciseIndex, exerciseDraft: exerciseDraft)
                    }
                }
                .padding()
            }
            .navigationTitle("ワークアウト中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("終了") {
                        showEndConfirm = true
                    }
                }
            }
            .onAppear {
                if viewModel == nil { viewModel = vm }
                vm.loadPreviousRecords()
                vm.loadMemoTags()
                restTimer.restoreFromUserDefaults()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                restTimer.restoreFromUserDefaults()
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    vm.addExercise(exercise)
                    showExercisePicker = false
                }
                .environment(\.modelContext, modelContext)
            }
            .alert("ワークアウトを終了", isPresented: $showEndConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("保存して終了") {
                    vm.saveSession()
                    showEndConfirm = false
                }
            } message: {
                Text("記録を保存して終了します。")
            }
        }
    }

    private func restTimerCard(restTimer: RestTimerManager) -> some View {
        SectionCard {
            HStack {
                Text("休憩 \(formatRestSeconds(restTimer.remainingSeconds))")
                    .font(.headline)
                Spacer()
                Button("スキップ") {
                    restTimer.skipRest()
                }
                .buttonStyle(.bordered)
                Button("+30秒") {
                    restTimer.extendRest(seconds: 30)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func formatRestSeconds(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func sessionHeader(startedAt: Date) -> some View {
        SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("開始 \(AppFormatters.formatDate(startedAt)) \(startedAt, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private func exerciseCard(viewModel: WorkoutRecordViewModel, exerciseIndex: Int, exerciseDraft: WorkoutExerciseDraft) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(exerciseDraft.exerciseName)
                    .font(.headline)
                if let summary = viewModel.previousRecordSummary(exerciseId: exerciseDraft.exerciseId) {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(exerciseDraft.sets.enumerated()), id: \.element.id) { setIndex, _ in
                    SetRowView(
                        orderIndex: setIndex,
                        weight: Binding(
                            get: { viewModel.weightString(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                            set: { viewModel.setWeight(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
                        ),
                        reps: Binding(
                            get: { viewModel.repsString(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                            set: { viewModel.setReps(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
                        ),
                        isCompleted: Binding(
                            get: { viewModel.isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                            set: { viewModel.setCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
                        ),
                        onCompleteToggle: nil
                    )
                }
                quickButtons(viewModel: viewModel, exerciseIndex: exerciseIndex, exerciseDraft: exerciseDraft)
                Button("+ セット追加") {
                    viewModel.addSet(exerciseIndex: exerciseIndex)
                }
                .font(.caption)
                if !viewModel.allMemoTags.isEmpty {
                    memoTagChips(viewModel: viewModel, exerciseIndex: exerciseIndex)
                }
                TextField("メモ（任意）", text: Binding(
                    get: { viewModel.draft.exercises[exerciseIndex].freeMemo },
                    set: { viewModel.setFreeMemo(exerciseIndex: exerciseIndex, $0) }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func memoTagChips(viewModel: WorkoutRecordViewModel, exerciseIndex: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.allMemoTags, id: \.id) { tag in
                    Button {
                        viewModel.toggleMemoTag(exerciseIndex: exerciseIndex, tagId: tag.id)
                    } label: {
                        Text(tag.label)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(viewModel.isMemoTagSelected(exerciseIndex: exerciseIndex, tagId: tag.id) ? Color.accentColor : Color.clear)
                            .foregroundStyle(viewModel.isMemoTagSelected(exerciseIndex: exerciseIndex, tagId: tag.id) ? Color.white : Color.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.accentColor, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func quickButtons(viewModel: WorkoutRecordViewModel, exerciseIndex: Int, exerciseDraft: WorkoutExerciseDraft) -> some View {
        if viewModel.previousRecordSummary(exerciseId: exerciseDraft.exerciseId) != nil, !exerciseDraft.sets.isEmpty {
            let targetSetIndex = exerciseDraft.sets.firstIndex(where: { !$0.isCompleted }) ?? (exerciseDraft.sets.count - 1)
            HStack(spacing: 8) {
                Button("前回と同じ") {
                    viewModel.applyPreviousToSet(exerciseIndex: exerciseIndex, setIndex: targetSetIndex)
                }
                .buttonStyle(.borderedProminent)
                Button("+1rep") {
                    viewModel.addRepToSet(exerciseIndex: exerciseIndex, setIndex: targetSetIndex)
                }
                .buttonStyle(.bordered)
                Button("+2.5kg") {
                    viewModel.addWeightToSet(exerciseIndex: exerciseIndex, setIndex: targetSetIndex, delta: 2.5)
                }
                .buttonStyle(.bordered)
                Button("-2.5kg") {
                    viewModel.addWeightToSet(exerciseIndex: exerciseIndex, setIndex: targetSetIndex, delta: -2.5)
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)
        }
    }
}

#Preview {
    WorkoutRecordView(draft: WorkoutSessionDraft(), onDismiss: {})
        .modelContainer(for: [WorkoutSession.self, Exercise.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
