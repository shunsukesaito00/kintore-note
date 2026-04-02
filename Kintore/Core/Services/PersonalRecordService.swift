// File: Core/Services/PersonalRecordService.swift
// PR = volume（weight × reps）最大の 1 セット。セット完了時に更新判定・保存。

import Foundation
import SwiftData

final class PersonalRecordService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 達成日が [start, end) に入る PR 件数（期間内にベストが更新された種目数の目安）。
    func countAchievedBetween(start: Date, end: Date) throws -> Int {
        let all = try modelContext.fetch(FetchDescriptor<PersonalRecord>())
        return all.filter { $0.achievedAt >= start && $0.achievedAt < end }.count
    }

    /// 登録されている PR レコード総数（種目ごとに最大1件）。
    func countAllRecords() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<PersonalRecord>())
    }

    /// 直近の PR 更新履歴（達成日降順）
    func fetchRecentPRs(limit: Int = 20) throws -> [PersonalRecord] {
        var descriptor = FetchDescriptor<PersonalRecord>(sortBy: [SortDescriptor(\.achievedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    /// 現在の種目 PR（あれば 1 件）
    func fetchPersonalRecord(exerciseId: UUID) throws -> PersonalRecord? {
        var descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { $0.exerciseId == exerciseId }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// このセットで PR 更新が必要か
    func shouldUpdatePR(exerciseId: UUID, weight: Double?, reps: Int?) -> Bool {
        let vol = VolumeCalculator.volume(weight: weight, reps: reps)
        guard vol > 0 else { return false }
        let existing = try? fetchPersonalRecord(exerciseId: exerciseId)
        if let ex = existing { return vol > ex.volume }
        return true
    }

    /// PR を 1 件更新または新規作成。セット完了時に呼ぶ。PR が更新された場合 true を返す。
    @discardableResult
    func updateIfNeeded(exerciseId: UUID, weight: Double, reps: Int, achievedAt: Date = Date()) throws -> Bool {
        let vol = VolumeCalculator.volume(weight: weight, reps: reps)
        if vol <= 0 { return false }

        var descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { $0.exerciseId == exerciseId }
        )
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first

        if let ex = existing {
            if vol <= ex.volume { return false }
            ex.weight = weight
            ex.reps = reps
            ex.volume = vol
            ex.achievedAt = achievedAt
        } else {
            let pr = PersonalRecord(exerciseId: exerciseId, weight: weight, reps: reps, volume: vol, achievedAt: achievedAt)
            modelContext.insert(pr)
        }
        try modelContext.save()
        return true
    }
}
