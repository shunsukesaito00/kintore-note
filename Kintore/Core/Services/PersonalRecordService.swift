// File: Core/Services/PersonalRecordService.swift
// PR = volume（weight × reps）最大の 1 セット。セット完了時に更新判定・保存。

import Foundation
import SwiftData

final class PersonalRecordService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 現在の種目 PR（あれば 1 件）
    func fetchPersonalRecord(exerciseId: UUID) throws -> PersonalRecord? {
        var descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { $0.exerciseId == exerciseId }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// セットの volume。重量・回数どちらか nil なら 0（PR 更新しない）
    private static func volume(weight: Double?, reps: Int?) -> Double? {
        guard let w = weight, let r = reps, w > 0, r > 0 else { return nil }
        return w * Double(r)
    }

    /// このセットで PR 更新が必要か
    func shouldUpdatePR(exerciseId: UUID, weight: Double?, reps: Int?) -> Bool {
        guard let vol = Self.volume(weight: weight, reps: reps), vol > 0 else { return false }
        let existing = try? fetchPersonalRecord(exerciseId: exerciseId)
        if let ex = existing { return vol > ex.volume }
        return true
    }

    /// PR を 1 件更新または新規作成。セット完了時に呼ぶ。
    func updateIfNeeded(exerciseId: UUID, weight: Double, reps: Int, achievedAt: Date = Date()) throws {
        let vol = weight * Double(reps)
        if vol <= 0 { return }

        var descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { $0.exerciseId == exerciseId }
        )
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first

        if let ex = existing {
            if vol <= ex.volume { return }
            ex.weight = weight
            ex.reps = reps
            ex.volume = vol
            ex.achievedAt = achievedAt
        } else {
            let pr = PersonalRecord(exerciseId: exerciseId, weight: weight, reps: reps, volume: vol, achievedAt: achievedAt)
            modelContext.insert(pr)
        }
        try modelContext.save()
    }
}
