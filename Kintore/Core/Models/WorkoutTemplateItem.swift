// File: Core/Models/WorkoutTemplateItem.swift

import Foundation
import SwiftData

@Model
final class WorkoutTemplateItem {
    var id: UUID
    var orderIndex: Int

    var template: WorkoutTemplate?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        orderIndex: Int = 0,
        template: WorkoutTemplate? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.template = template
        self.exercise = exercise
    }
}
