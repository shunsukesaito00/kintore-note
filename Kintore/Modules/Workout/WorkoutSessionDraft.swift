// File: Modules/Workout/WorkoutSessionDraft.swift

import Foundation

struct WorkoutSessionDraft: Identifiable {
    var id: UUID
    var startedAt: Date
    var templateId: UUID?
    var templateName: String?
    var exercises: [WorkoutExerciseDraft]

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        templateId: UUID? = nil,
        templateName: String? = nil,
        exercises: [WorkoutExerciseDraft] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.templateId = templateId
        self.templateName = templateName
        self.exercises = exercises
    }
}
