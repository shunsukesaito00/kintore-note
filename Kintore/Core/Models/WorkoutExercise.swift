// File: Core/Models/WorkoutExercise.swift
// メモタグは memoTagIdsString（カンマ区切り）で保持。Service 層で [String] にパースする。

import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    var id: UUID
    var orderIndex: Int
    var memoTagIdsString: String
    var freeMemo: String?
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
        createdAt: Date = Date(),
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.memoTagIdsString = memoTagIdsString
        self.freeMemo = freeMemo
        self.createdAt = createdAt
        self.session = session
        self.exercise = exercise
    }
}
