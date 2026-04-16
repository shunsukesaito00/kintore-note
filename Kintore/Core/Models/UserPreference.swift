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
    /// 週あたりのトレーニング目標（完了セッション数）。0 は未設定。
    var weeklyWorkoutGoalSessions: Int
    /// 月あたりのトレーニング目標（完了セッション数）。0 は未設定。
    var monthlyWorkoutGoalSessions: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        defaultRestSeconds: Int = 90,
        weightUnit: String = "kg",
        theme: String = "system",
        weeklyWorkoutGoalSessions: Int = 0,
        monthlyWorkoutGoalSessions: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.defaultRestSeconds = defaultRestSeconds
        self.weightUnit = weightUnit
        self.theme = theme
        self.weeklyWorkoutGoalSessions = weeklyWorkoutGoalSessions
        self.monthlyWorkoutGoalSessions = monthlyWorkoutGoalSessions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
