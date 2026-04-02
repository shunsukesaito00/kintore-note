// File: Modules/Workout/WorkoutSetDraft.swift

import Foundation

/// セット種別。STRONG のウォームアップ / Failure / ドロップセットに相当。
enum SetTypeTag: String, CaseIterable {
    case normal = "normal"
    case warmup = "warmup"
    case failure = "failure"
    case drop = "drop"

    var displayName: String {
        switch self {
        case .normal: return "通常"
        case .warmup: return "ウォームアップ"
        case .failure: return "Failure"
        case .drop: return "ドロップ"
        }
    }

    /// メニュー1行表示用（筋トレメモ風の短い表記）
    var menuLineTitle: String {
        switch self {
        case .normal: return "通常"
        case .warmup: return "ウォームアップ"
        case .failure: return "限界"
        case .drop: return "ドロップ"
        }
    }

    /// セット表の「種別」列用の短縮表示（Localizable）
    var abbreviation: String {
        switch self {
        case .normal: return String(localized: "set_type_abbr_normal")
        case .warmup: return String(localized: "set_type_abbr_warmup")
        case .failure: return String(localized: "set_type_abbr_failure")
        case .drop: return String(localized: "set_type_abbr_drop")
        }
    }
}

struct WorkoutSetDraft: Identifiable {
    var id: UUID
    var weight: Double?
    var reps: Int?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var inclinePercent: Double?
    var speedKmh: Double?
    var orderIndex: Int
    var isCompleted: Bool
    var completedAt: Date?
    var setType: String
    /// RPE（主観的強度）1–10。nil は未入力。
    var rpe: Int?
    /// 補助あり。既定 false。
    var isAssisted: Bool
    /// セット単位メモ（任意）
    var setNote: String?

    init(
        id: UUID = UUID(),
        weight: Double? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil,
        inclinePercent: Double? = nil,
        speedKmh: Double? = nil,
        orderIndex: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        setType: String = SetTypeTag.normal.rawValue,
        rpe: Int? = nil,
        isAssisted: Bool = false,
        setNote: String? = nil
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.inclinePercent = inclinePercent
        self.speedKmh = speedKmh
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.setType = setType
        self.rpe = rpe
        self.isAssisted = isAssisted
        self.setNote = setNote
    }
}
