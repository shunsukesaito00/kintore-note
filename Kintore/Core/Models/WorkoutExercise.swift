// File: Core/Models/WorkoutExercise.swift
// `memoTagIdsString` は旧データ互換のため残す（新規保存は空）。

import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    var id: UUID
    var orderIndex: Int
    var memoTagIdsString: String
    var freeMemo: String?
    /// 隣接する2種目をスーパーセットで結ぶとき同じ UUID。単独種目は nil。
    var supersetGroupId: UUID?
    var createdAt: Date

    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet] = []

    init(
        id: UUID = UUID(),
        orderIndex: Int = 0,
        memoTagIdsString: String = "",
        freeMemo: String? = nil,
        supersetGroupId: UUID? = nil,
        createdAt: Date = Date(),
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.memoTagIdsString = memoTagIdsString
        self.freeMemo = freeMemo
        self.supersetGroupId = supersetGroupId
        self.createdAt = createdAt
        self.session = session
        self.exercise = exercise
    }
}
