// File: Modules/Workout/WorkoutRecordViewModel.swift

import Foundation
import SwiftData

@Observable
final class WorkoutRecordViewModel {
    var draft: WorkoutSessionDraft
    var previousRecords: [UUID: PreviousRecordDTO] = [:]
    var saveError: String?
    var isSaving = false

    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let previousRecordService: PreviousRecordService
    private let personalRecordService: PersonalRecordService
    private let modelContext: ModelContext

    init(
        draft: WorkoutSessionDraft,
        workoutRepository: WorkoutRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol,
        previousRecordService: PreviousRecordService,
        personalRecordService: PersonalRecordService,
        modelContext: ModelContext
    ) {
        self.draft = draft
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.previousRecordService = previousRecordService
        self.personalRecordService = personalRecordService
        self.modelContext = modelContext
    }

    func loadPreviousRecords() {
        for ex in draft.exercises {
            if let dto = try? previousRecordService.fetchPreviousRecord(exerciseId: ex.exerciseId) {
                previousRecords[ex.exerciseId] = dto
            }
        }
    }

    func addExercise(_ exercise: Exercise) {
        let new = WorkoutExerciseDraft(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            orderIndex: draft.exercises.count,
            sets: [WorkoutSetDraft(orderIndex: 0)]
        )
        draft.exercises.append(new)
        if let dto = try? previousRecordService.fetchPreviousRecord(exerciseId: exercise.id) {
            previousRecords[exercise.id] = dto
        }
    }

    func addSet(exerciseIndex: Int) {
        guard exerciseIndex < draft.exercises.count else { return }
        let order = draft.exercises[exerciseIndex].sets.count
        draft.exercises[exerciseIndex].sets.append(WorkoutSetDraft(orderIndex: order))
    }

    func setWeight(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let v = Double(string.replacingOccurrences(of: ",", with: "."))
        draft.exercises[exerciseIndex].sets[setIndex].weight = v
    }

    func setReps(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].reps = Int(string)
    }

    func setCompleted(exerciseIndex: Int, setIndex: Int, _ completed: Bool) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].isCompleted = completed
        if completed {
            draft.exercises[exerciseIndex].sets[setIndex].completedAt = Date()
        } else {
            draft.exercises[exerciseIndex].sets[setIndex].completedAt = nil
        }
    }

    func setFreeMemo(exerciseIndex: Int, _ text: String) {
        guard exerciseIndex < draft.exercises.count else { return }
        draft.exercises[exerciseIndex].freeMemo = text
    }

    func weightString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        let w = draft.exercises[exerciseIndex].sets[setIndex].weight
        guard let w = w else { return "" }
        return w == floor(w) ? "\(Int(w))" : "\(w)"
    }

    func repsString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        let r = draft.exercises[exerciseIndex].sets[setIndex].reps
        return r.map { "\($0)" } ?? ""
    }

    func isSetCompleted(exerciseIndex: Int, setIndex: Int) -> Bool {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return false }
        return draft.exercises[exerciseIndex].sets[setIndex].isCompleted
    }

    func previousRecordSummary(exerciseId: UUID) -> String? {
        guard let dto = previousRecords[exerciseId] else { return nil }
        let w = dto.weight.map { "\(Int($0))" } ?? "—"
        let r = dto.reps.map { "\($0)" } ?? "—"
        let dateStr = dto.date.map { AppFormatters.formatDateWithWeekday($0) } ?? ""
        if dateStr.isEmpty {
            return "前回 \(w)kg × \(r) × \(dto.setCount)セット"
        }
        return "前回 \(w)kg × \(r) × \(dto.setCount)セット 最終 \(dateStr)"
    }

    func saveSession() {
        isSaving = true
        saveError = nil
        do {
            var lookup: [UUID: Exercise] = [:]
            for exDraft in draft.exercises {
                if let ex = try exerciseRepository.fetchExercise(by: exDraft.exerciseId) {
                    lookup[exDraft.exerciseId] = ex
                }
            }
            var template: WorkoutTemplate?
            if let tid = draft.templateId {
                template = try TemplateRepository(modelContext: modelContext).fetchTemplate(by: tid)
            }
            _ = try workoutRepository.saveSession(from: draft, exerciseLookup: lookup, template: template)
            for exDraft in draft.exercises {
                for setDraft in exDraft.sets where setDraft.isCompleted {
                    guard let w = setDraft.weight, let r = setDraft.reps, w > 0, r > 0 else { continue }
                    try? personalRecordService.updateIfNeeded(exerciseId: exDraft.exerciseId, weight: w, reps: r, achievedAt: setDraft.completedAt ?? Date())
                }
            }
            isSaving = false
            onSaveSuccess?()
        } catch {
            saveError = error.localizedDescription
            isSaving = false
        }
    }

    var onSaveSuccess: (() -> Void)?
}
