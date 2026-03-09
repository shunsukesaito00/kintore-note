// File: Core/Models/Exercise.swift

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var bodyPartTag: String
    var equipmentTag: String
    var defaultRestSeconds: Int?
    var isPreset: Bool
    var isFavorite: Bool
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        bodyPartTag: String = "",
        equipmentTag: String = "",
        defaultRestSeconds: Int? = nil,
        isPreset: Bool = false,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bodyPartTag = bodyPartTag
        self.equipmentTag = equipmentTag
        self.defaultRestSeconds = defaultRestSeconds
        self.isPreset = isPreset
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
