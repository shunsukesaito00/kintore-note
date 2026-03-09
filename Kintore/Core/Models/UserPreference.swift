// File: Core/Models/UserPreference.swift
// 初版は 1 件のみ（シングルトン運用）。種目別休憩上書きは将来用にフィールドだけ残す。

import Foundation
import SwiftData

@Model
final class UserPreference {
    var id: UUID
    var defaultRestSeconds: Int
    var weightUnit: String
    var theme: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        defaultRestSeconds: Int = 90,
        weightUnit: String = "kg",
        theme: String = "system",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.defaultRestSeconds = defaultRestSeconds
        self.weightUnit = weightUnit
        self.theme = theme
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
