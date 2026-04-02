// File: Core/Services/PreviousRecordService.swift
// 同一種目の直近完了記録を取得し、画面用 DTO で返す。

import Foundation
import SwiftData

/// 前回セット1行分（種目タイプに応じて使うフィールドが異なる）
struct PreviousSetSnapshot {
    var weight: Double?
    var reps: Int?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var inclinePercent: Double?
    var speedKmh: Double?
}

struct PreviousRecordDTO {
    var exerciseKind: ExerciseKind
    /// 有酸素の入力レイアウト（`Exercise.cardioInputStyle`）
    var cardioInputStyle: String?
    var weight: Double?
    var reps: Int?
    var setCount: Int
    var date: Date?
    var sets: [PreviousSetSnapshot]
}

final class PreviousRecordService {
    private let workoutRepository: WorkoutRepositoryProtocol

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    /// 種目 ID に対する前回記録。なければ nil。
    func fetchPreviousRecord(exerciseId: UUID) throws -> PreviousRecordDTO? {
        guard let we = try workoutRepository.fetchPreviousWorkoutExercise(for: exerciseId) else { return nil }
        let sets = workoutRepository.fetchWorkoutSets(for: we)
        let setCount = sets.count
        let firstSet = sets.first
        let date = we.session?.endedAt ?? we.session?.startedAt
        let kind = ExerciseKind(stored: we.exercise?.exerciseKind)

        let snapshots: [PreviousSetSnapshot] = sets.map { s in
            PreviousSetSnapshot(
                weight: s.weight,
                reps: s.reps,
                durationSeconds: s.durationSeconds,
                distanceMeters: s.distanceMeters,
                inclinePercent: s.inclinePercent,
                speedKmh: s.speedKmh
            )
        }
        return PreviousRecordDTO(
            exerciseKind: kind,
            cardioInputStyle: we.exercise?.cardioInputStyle,
            weight: firstSet?.weight,
            reps: firstSet?.reps,
            setCount: setCount,
            date: date,
            sets: snapshots
        )
    }
}
