// File: Modules/Workout/WorkoutExerciseDraft.swift

import Foundation

struct WorkoutExerciseDraft: Identifiable {
    var id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var orderIndex: Int
    var sets: [WorkoutSetDraft]
    var freeMemo: String

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        orderIndex: Int = 0,
        sets: [WorkoutSetDraft] = [],
        freeMemo: String = ""
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.sets = sets
        self.freeMemo = freeMemo
    }
}
