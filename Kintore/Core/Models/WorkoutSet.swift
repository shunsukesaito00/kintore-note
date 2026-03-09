// File: Core/Models/WorkoutSet.swift

import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID
    var weight: Double?
    var reps: Int?
    var orderIndex: Int
    var completedAt: Date?

    var workoutExercise: WorkoutExercise?

    init(
        id: UUID = UUID(),
        weight: Double? = nil,
        reps: Int? = nil,
        orderIndex: Int = 0,
        completedAt: Date? = nil,
        workoutExercise: WorkoutExercise? = nil
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.orderIndex = orderIndex
        self.completedAt = completedAt
        self.workoutExercise = workoutExercise
    }

    /// volume = weight × reps。nil の場合は 0。
    var volume: Double {
        guard let w = weight, let r = reps, w > 0, r > 0 else { return 0 }
        return w * Double(r)
    }
}
