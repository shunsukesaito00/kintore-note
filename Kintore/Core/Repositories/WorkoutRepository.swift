// File: Core/Repositories/WorkoutRepository.swift

import Foundation
import SwiftData

protocol WorkoutRepositoryProtocol {
    func createSession(template: WorkoutTemplate?) throws -> WorkoutSession
    func fetchRecentSessions(limit: Int) throws -> [WorkoutSession]
    func fetchSession(by id: UUID) throws -> WorkoutSession?
    func saveWorkoutSession(_ session: WorkoutSession) throws
    func fetchPreviousWorkoutExercise(for exerciseId: UUID) throws -> WorkoutExercise?
    func fetchWorkoutExercises(for session: WorkoutSession) -> [WorkoutExercise]
    func fetchWorkoutSets(for workoutExercise: WorkoutExercise) -> [WorkoutSet]
    /// Draft から永続モデルを生成して保存。PR 更新は呼び出し側で行う。
    func saveSession(from draft: WorkoutSessionDraft, exerciseLookup: [UUID: Exercise], template: WorkoutTemplate?) throws -> WorkoutSession
}

final class WorkoutRepository: WorkoutRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createSession(template: WorkoutTemplate?) throws -> WorkoutSession {
        let session = WorkoutSession(startedAt: Date(), template: template)
        modelContext.insert(session)
        try modelContext.save()
        return session
    }

    func fetchRecentSessions(limit: Int) throws -> [WorkoutSession] {
        var descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func fetchSession(by id: UUID) throws -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate<WorkoutSession> { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func saveWorkoutSession(_ session: WorkoutSession) throws {
        try modelContext.save()
    }

    /// 同一種目（exerciseId）で、endedAt が存在するセッションに含まれる WorkoutExercise のうち、セッションの endedAt が最も新しい 1 件。
    func fetchPreviousWorkoutExercise(for exerciseId: UUID) throws -> WorkoutExercise? {
        // 完了済みセッションのみ。endedAt 降順でセッションを取得し、その中から該当種目の WorkoutExercise を探す。
        var sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil
            },
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 100
        let sessions = try modelContext.fetch(sessionDescriptor)

        for session in sessions {
            let exercises = session.workoutExercises.filter { we in
                we.exercise?.id == exerciseId
            }
            if let first = exercises.first {
                return first
            }
        }
        return nil
    }

    func fetchWorkoutExercises(for session: WorkoutSession) -> [WorkoutExercise] {
        session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    func fetchWorkoutSets(for workoutExercise: WorkoutExercise) -> [WorkoutSet] {
        workoutExercise.sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    func saveSession(from draft: WorkoutSessionDraft, exerciseLookup: [UUID: Exercise], template: WorkoutTemplate?) throws -> WorkoutSession {
        let endedAt = Date()
        let durationSeconds = Int(endedAt.timeIntervalSince(draft.startedAt))
        let session = WorkoutSession(
            startedAt: draft.startedAt,
            endedAt: endedAt,
            durationSeconds: max(0, durationSeconds),
            template: template
        )
        modelContext.insert(session)

        for exerciseDraft in draft.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            guard let exercise = exerciseLookup[exerciseDraft.exerciseId] else { continue }
            let we = WorkoutExercise(
                orderIndex: exerciseDraft.orderIndex,
                freeMemo: exerciseDraft.freeMemo.isEmpty ? nil : exerciseDraft.freeMemo,
                session: session,
                exercise: exercise
            )
            modelContext.insert(we)
            for setDraft in exerciseDraft.sets.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let ws = WorkoutSet(
                    weight: setDraft.weight,
                    reps: setDraft.reps,
                    orderIndex: setDraft.orderIndex,
                    completedAt: setDraft.isCompleted ? (setDraft.completedAt ?? endedAt) : nil,
                    workoutExercise: we
                )
                modelContext.insert(ws)
            }
        }
        try modelContext.save()
        return session
    }
}
