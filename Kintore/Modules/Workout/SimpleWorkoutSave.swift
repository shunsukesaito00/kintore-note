// File: Modules/Workout/SimpleWorkoutSave.swift
// 簡易記録: 種目ごと最大重量1セットでセッション保存

import Foundation
import SwiftData

enum SimpleWorkoutSave {
    /// 重量は表示単位に応じて kg に正規化して保存する。
    static func commit(
        exercises: [Exercise],
        weightTextById: [UUID: String],
        displayWeightUnit: String,
        modelContext: ModelContext
    ) throws -> WorkoutSession {
        let repo = WorkoutRepository(modelContext: modelContext)
        let exRepo = ExerciseRepository(modelContext: modelContext)

        var anyWeight = false
        for ex in exercises {
            let raw = weightTextById[ex.id] ?? ""
            let trimmed = raw.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, Double(trimmed) != nil { anyWeight = true; break }
        }
        guard anyWeight else {
            throw NSError(
                domain: "SimpleWorkoutSave",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: String(localized: "simple_record_error_no_weight")]
            )
        }

        var exercisesDraft: [WorkoutExerciseDraft] = []
        for (idx, ex) in exercises.enumerated() {
            let raw = weightTextById[ex.id] ?? ""
            let trimmed = raw.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
            let kg: Double?
            if trimmed.isEmpty {
                kg = nil
            } else if let v = Double(trimmed) {
                kg = displayWeightUnit == "lb" ? AppFormatters.poundsToKilograms(v) : v
            } else {
                kg = nil
            }

            let set = WorkoutSetDraft(
                weight: kg,
                reps: kg != nil ? 1 : nil,
                orderIndex: 0,
                isCompleted: kg != nil,
                completedAt: kg != nil ? Date() : nil
            )
            exercisesDraft.append(
                WorkoutExerciseDraft(
                    exerciseId: ex.id,
                    exerciseName: ex.name,
                    exerciseKind: ex.exerciseKind,
                    cardioInputStyle: ex.cardioInputStyle,
                    orderIndex: idx,
                    sets: [set]
                )
            )
        }

        let base = WorkoutSessionDraft(exercises: exercisesDraft)
        let merged = try repo.resolveDraftForStartingWorkoutToday(base: base)

        let allIds = Set(merged.exercises.map(\.exerciseId))
        var lookup: [UUID: Exercise] = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        for id in allIds {
            if lookup[id] == nil, let e = try? exRepo.fetchExercise(by: id) {
                lookup[id] = e
            }
        }

        if let resumeId = merged.resumingPersistentSessionId {
            return try repo.completeIncompleteSession(sessionId: resumeId, from: merged, exerciseLookup: lookup, template: nil)
        }
        return try repo.saveSession(from: merged, exerciseLookup: lookup, template: nil)
    }
}
