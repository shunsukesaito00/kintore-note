// File: Modules/Workout/WorkoutExerciseDraft.swift

import Foundation

struct WorkoutExerciseDraft: Identifiable {
    var id: UUID
    var exerciseId: UUID
    var exerciseName: String
    /// `ExerciseKind` の rawValue
    var exerciseKind: String
    /// `Exercise.cardioInputStyle`（有酸素の入力レイアウト）
    var cardioInputStyle: String?
    var orderIndex: Int
    var sets: [WorkoutSetDraft]
    var freeMemo: String
    /// `WorkoutExercise.supersetGroupId` と同じ。隣接2種目のペア用。
    var supersetGroupId: UUID?

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        exerciseKind: String = ExerciseKind.strength.rawValue,
        cardioInputStyle: String? = nil,
        orderIndex: Int = 0,
        sets: [WorkoutSetDraft] = [],
        freeMemo: String = "",
        supersetGroupId: UUID? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.exerciseKind = exerciseKind
        self.cardioInputStyle = cardioInputStyle
        self.orderIndex = orderIndex
        self.sets = sets
        self.freeMemo = freeMemo
        self.supersetGroupId = supersetGroupId
    }
}
