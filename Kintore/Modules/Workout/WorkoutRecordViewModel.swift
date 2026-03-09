// File: Modules/Workout/WorkoutRecordViewModel.swift

import Foundation
import SwiftData

@Observable
final class WorkoutRecordViewModel {
    var draft: WorkoutSessionDraft
    var previousRecords: [UUID: PreviousRecordDTO] = [:]
    var allMemoTags: [MemoTag] = []
    var saveError: String?
    var isSaving = false

    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let previousRecordService: PreviousRecordService
    private let personalRecordService: PersonalRecordService
    private let memoTagRepository: MemoTagRepository?
    private let settingsRepository: SettingsRepositoryProtocol?
    private let modelContext: ModelContext
    weak var restTimerManager: RestTimerManager?

    init(
        draft: WorkoutSessionDraft,
        workoutRepository: WorkoutRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol,
        previousRecordService: PreviousRecordService,
        personalRecordService: PersonalRecordService,
        memoTagRepository: MemoTagRepository? = nil,
        settingsRepository: SettingsRepositoryProtocol? = nil,
        restTimerManager: RestTimerManager? = nil,
        modelContext: ModelContext
    ) {
        self.draft = draft
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.previousRecordService = previousRecordService
        self.personalRecordService = personalRecordService
        self.memoTagRepository = memoTagRepository
        self.settingsRepository = settingsRepository
        self.restTimerManager = restTimerManager
        self.modelContext = modelContext
    }

    func loadPreviousRecords() {
        for ex in draft.exercises {
            if let dto = try? previousRecordService.fetchPreviousRecord(exerciseId: ex.exerciseId) {
                previousRecords[ex.exerciseId] = dto
            }
        }
    }

    func loadMemoTags() {
        guard let repo = memoTagRepository else { return }
        allMemoTags = (try? repo.fetchAll()) ?? []
    }

    func toggleMemoTag(exerciseIndex: Int, tagId: String) {
        guard exerciseIndex < draft.exercises.count else { return }
        var ids = draft.exercises[exerciseIndex].memoTagIds
        if ids.contains(tagId) {
            ids.removeAll { $0 == tagId }
        } else {
            ids.append(tagId)
        }
        draft.exercises[exerciseIndex].memoTagIds = ids
    }

    func isMemoTagSelected(exerciseIndex: Int, tagId: String) -> Bool {
        guard exerciseIndex < draft.exercises.count else { return false }
        return draft.exercises[exerciseIndex].memoTagIds.contains(tagId)
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
            startRestAfterSetCompleted(exerciseIndex: exerciseIndex)
        } else {
            draft.exercises[exerciseIndex].sets[setIndex].completedAt = nil
        }
    }

    private func startRestAfterSetCompleted(exerciseIndex: Int) {
        guard let rest = restTimerManager else { return }
        let seconds: Int
        if exerciseIndex < draft.exercises.count,
           let ex = try? exerciseRepository.fetchExercise(by: draft.exercises[exerciseIndex].exerciseId),
           let s = ex.defaultRestSeconds, s > 0 {
            seconds = s
        } else if let pref = try? settingsRepository?.fetchUserPreference(), pref.defaultRestSeconds > 0 {
            seconds = pref.defaultRestSeconds
        } else {
            seconds = 90
        }
        RestTimerManager.requestNotificationPermissionIfNeeded()
        rest.startRest(seconds: seconds)
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

    /// 指定セットに前回の値（セット番目）をコピー。セットが前回より多ければ1セット目の値を使う。
    func applyPreviousToSet(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let exDraft = draft.exercises[exerciseIndex]
        guard let dto = previousRecords[exDraft.exerciseId], !dto.sets.isEmpty else { return }
        let idx = min(setIndex, dto.sets.count - 1)
        let t = dto.sets[idx]
        draft.exercises[exerciseIndex].sets[setIndex].weight = t.0
        draft.exercises[exerciseIndex].sets[setIndex].reps = t.1
    }

    func addRepToSet(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let exDraft = draft.exercises[exerciseIndex]
        guard let dto = previousRecords[exDraft.exerciseId] else { return }
        let prevReps = setIndex < dto.sets.count ? dto.sets[setIndex].1 : dto.reps
        let current = draft.exercises[exerciseIndex].sets[setIndex].reps ?? prevReps ?? 0
        draft.exercises[exerciseIndex].sets[setIndex].reps = current + 1
    }

    func addWeightToSet(exerciseIndex: Int, setIndex: Int, delta: Double) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let exDraft = draft.exercises[exerciseIndex]
        guard let dto = previousRecords[exDraft.exerciseId] else { return }
        let prevWeight = setIndex < dto.sets.count ? dto.sets[setIndex].0 : dto.weight
        let current = draft.exercises[exerciseIndex].sets[setIndex].weight ?? prevWeight ?? 0
        draft.exercises[exerciseIndex].sets[setIndex].weight = max(0, current + delta)
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
