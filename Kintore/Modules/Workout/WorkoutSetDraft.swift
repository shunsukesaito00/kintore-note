// File: Modules/Workout/WorkoutSetDraft.swift

import Foundation

struct WorkoutSetDraft: Identifiable {
    var id: UUID
    var weight: Double?
    var reps: Int?
    var orderIndex: Int
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        weight: Double? = nil,
        reps: Int? = nil,
        orderIndex: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
