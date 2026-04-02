// File: Modules/Workout/WorkoutSessionDraft.swift

import Foundation
import SwiftData

struct WorkoutSessionDraft: Identifiable {
    var id: UUID
    var startedAt: Date
    var templateId: UUID?
    var templateName: String?
    var exercises: [WorkoutExerciseDraft]
    /// 未完了セッションを再開しているときの永続セッション ID。保存時に既存行を完了更新する。
    var resumingPersistentSessionId: UUID?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        templateId: UUID? = nil,
        templateName: String? = nil,
        exercises: [WorkoutExerciseDraft] = [],
        resumingPersistentSessionId: UUID? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.templateId = templateId
        self.templateName = templateName
        self.exercises = exercises
        self.resumingPersistentSessionId = resumingPersistentSessionId
    }
}

extension WorkoutSessionDraft {
    /// 完了済みセッションを元に、同じ種目・セット内容の新規ワークアウト用ドラフトを作る（セットはすべて未完了）。
    /// 削除済み種目はスキップ。スーパーセットIDは並びが変わり得るためクリアする。
    init?(repeating session: WorkoutSession) {
        guard session.endedAt != nil else { return nil }
        let sorted = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        var drafts: [WorkoutExerciseDraft] = []
        var order = 0
        for we in sorted {
            guard let ex = we.exercise else { continue }
            let setsSorted = we.sets.sorted { $0.orderIndex < $1.orderIndex }
            let setDrafts: [WorkoutSetDraft] = setsSorted.enumerated().map { i, s in
                let st = s.setType ?? SetTypeTag.normal.rawValue
                return WorkoutSetDraft(
                    id: UUID(),
                    weight: s.weight,
                    reps: s.reps,
                    durationSeconds: s.durationSeconds,
                    distanceMeters: s.distanceMeters,
                    inclinePercent: s.inclinePercent,
                    speedKmh: s.speedKmh,
                    orderIndex: i,
                    isCompleted: false,
                    completedAt: nil,
                    setType: st,
                    rpe: s.rpe,
                    isAssisted: s.isAssisted ?? false,
                    setNote: s.setNote
                )
            }
            guard !setDrafts.isEmpty else { continue }
            drafts.append(
                WorkoutExerciseDraft(
                    id: UUID(),
                    exerciseId: ex.id,
                    exerciseName: ex.name,
                    exerciseKind: ex.exerciseKind,
                    cardioInputStyle: ex.cardioInputStyle,
                    orderIndex: order,
                    sets: setDrafts,
                    freeMemo: we.freeMemo ?? "",
                    supersetGroupId: nil
                )
            )
            order += 1
        }
        guard !drafts.isEmpty else { return nil }
        self.init(
            startedAt: Date(),
            templateId: nil,
            templateName: nil,
            exercises: drafts
        )
    }

    /// 未完了セッション（`endedAt == nil`）からドラフトを復元する。
    init?(resuming session: WorkoutSession) {
        guard session.endedAt == nil else { return nil }
        let sorted = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        var drafts: [WorkoutExerciseDraft] = []
        var order = 0
        for we in sorted {
            guard let ex = we.exercise else { continue }
            let setsSorted = we.sets.sorted { $0.orderIndex < $1.orderIndex }
            let setDrafts: [WorkoutSetDraft] = setsSorted.enumerated().map { i, s in
                let st = s.setType ?? SetTypeTag.normal.rawValue
                return WorkoutSetDraft(
                    id: s.id,
                    weight: s.weight,
                    reps: s.reps,
                    durationSeconds: s.durationSeconds,
                    distanceMeters: s.distanceMeters,
                    inclinePercent: s.inclinePercent,
                    speedKmh: s.speedKmh,
                    orderIndex: i,
                    isCompleted: s.completedAt != nil,
                    completedAt: s.completedAt,
                    setType: st,
                    rpe: s.rpe,
                    isAssisted: s.isAssisted ?? false,
                    setNote: s.setNote
                )
            }
            drafts.append(
                WorkoutExerciseDraft(
                    id: we.id,
                    exerciseId: ex.id,
                    exerciseName: ex.name,
                    exerciseKind: ex.exerciseKind,
                    cardioInputStyle: ex.cardioInputStyle,
                    orderIndex: order,
                    sets: setDrafts.isEmpty ? [WorkoutSetDraft(orderIndex: 0)] : setDrafts,
                    freeMemo: we.freeMemo ?? "",
                    supersetGroupId: we.supersetGroupId
                )
            )
            order += 1
        }
        self.init(
            id: UUID(),
            startedAt: session.startedAt,
            templateId: session.template?.id,
            templateName: session.template?.name,
            exercises: drafts,
            resumingPersistentSessionId: session.id
        )
    }
}

