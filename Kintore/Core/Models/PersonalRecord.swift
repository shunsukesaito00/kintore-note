// File: Core/Models/PersonalRecord.swift
// PR = 同一種目で volume（weight × reps）が最大の 1 セット。exerciseId で種目を識別。

import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var id: UUID
    var exerciseId: UUID
    var weight: Double
    var reps: Int
    var volume: Double
    var achievedAt: Date

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        weight: Double,
        reps: Int,
        volume: Double,
        achievedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.volume = volume
        self.achievedAt = achievedAt
    }
}
