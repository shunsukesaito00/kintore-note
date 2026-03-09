// File: Core/Services/PreviousRecordService.swift
// 同一種目の直近完了記録を取得し、画面用 DTO で返す。

import Foundation
import SwiftData

struct PreviousRecordDTO {
    var weight: Double?
    var reps: Int?
    var setCount: Int
    var date: Date?
    var sets: [(weight: Double?, reps: Int?)] // 各セットの重量・回数（前回と同じコピー用）
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

        let setTuples: [(Double?, Int?)] = sets.map { ($0.weight, $0.reps) }
        return PreviousRecordDTO(
            weight: firstSet?.weight,
            reps: firstSet?.reps,
            setCount: setCount,
            date: date,
            sets: setTuples.map { ($0.0, $0.1) }
        )
    }
}
