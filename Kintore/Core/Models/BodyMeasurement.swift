// File: Core/Models/BodyMeasurement.swift
// 体重・体脂肪率などの身体記録（時系列）。

import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var id: UUID
    /// 測定日時（ユーザーが選んだ日付）
    var measuredAt: Date
    /// 体重（kg）
    var weightKg: Double?
    /// 体脂肪率（%）任意
    var bodyFatPercent: Double?
    var note: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        measuredAt: Date = Date(),
        weightKg: Double? = nil,
        bodyFatPercent: Double? = nil,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.measuredAt = measuredAt
        self.weightKg = weightKg
        self.bodyFatPercent = bodyFatPercent
        self.note = note
        self.createdAt = createdAt
    }
}
