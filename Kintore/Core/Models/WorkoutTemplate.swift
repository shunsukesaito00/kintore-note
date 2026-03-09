// File: Core/Models/WorkoutTemplate.swift

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var memo: String?
    var sortOrder: Int
    var createdAt: Date
    var lastUsedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateItem.template)
    var items: [WorkoutTemplateItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        memo: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.memo = memo
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
