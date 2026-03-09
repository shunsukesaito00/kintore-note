// File: Modules/Workout/WorkoutRecordView.swift

import SwiftUI
import SwiftData

struct WorkoutRecordView: View {
    @Environment(\.modelContext) private var modelContext
    let draft: WorkoutSessionDraft
    let onDismiss: () -> Void

    @State private var viewModel: WorkoutRecordViewModel?
    @State private var showExercisePicker = false
    @State private var showEndConfirm = false

    var body: some View {
        let vm: WorkoutRecordViewModel = {
            if let v = viewModel { return v }
            let w = WorkoutRepository(modelContext: modelContext)
            let e = ExerciseRepository(modelContext: modelContext)
            let prev = PreviousRecordService(workoutRepository: w)
            let pr = PersonalRecordService(modelContext: modelContext)
            let v = WorkoutRecordViewModel(
                draft: draft,
                workoutRepository: w,
                exerciseRepository: e,
                previousRecordService: prev,
                personalRecordService: pr,
                modelContext: modelContext
            )
            v.onSaveSuccess = onDismiss
            return v
        }()
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sessionHeader(startedAt: vm.draft.startedAt)

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
                Button("+ セット追加") {
                    viewModel.addSet(exerciseIndex: exerciseIndex)
                }
                .font(.caption)
                TextField("メモ（任意）", text: Binding(
                    get: { viewModel.draft.exercises[exerciseIndex].freeMemo },
                    set: { viewModel.setFreeMemo(exerciseIndex: exerciseIndex, $0) }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }
}

#Preview {
    WorkoutRecordView(draft: WorkoutSessionDraft(), onDismiss: {})
        .modelContainer(for: [WorkoutSession.self, Exercise.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
