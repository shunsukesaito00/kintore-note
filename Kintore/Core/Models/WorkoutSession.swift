// File: Core/Models/WorkoutSession.swift

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int?
    var createdAt: Date

    var template: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.session)
    var workoutExercises: [WorkoutExercise] = []

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Int? = nil,
        createdAt: Date = Date(),
        template: WorkoutTemplate? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.createdAt = createdAt
        self.template = template
    }
}
