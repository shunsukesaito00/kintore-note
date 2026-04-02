// File: Core/Models/WorkoutSet.swift

import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID
    var weight: Double?
    var reps: Int?
    /// 時間系種目の秒数（プランク等）。筋トレでは通常未使用。
    var durationSeconds: Int?
    /// 有酸素の距離（メートル）。表示は km に換算可。
    var distanceMeters: Double?
    /// トレッドミル有酸素: 傾斜（%）
    var inclinePercent: Double?
    /// トレッドミル有酸素: 速度（km/h）
    var speedKmh: Double?
    var orderIndex: Int
    var completedAt: Date?
    /// セット種別: "warmup", "failure", "drop", nil = 通常（本番）
    var setType: String?
    /// RPE（主観的強度）1–10。nil は未入力。
    var rpe: Int?
    /// 補助あり（スポッター等）。`nil` は未設定／旧データ（＝補助なしとして扱う）。
    /// 永続ストアの軽量マイグレーション互換のため **Optional**（非オプショナル Bool の追加はコンテナ生成に失敗しやすい）。
    var isAssisted: Bool?
    /// セット単位メモ（任意）
    var setNote: String?

    var workoutExercise: WorkoutExercise?

    init(
        id: UUID = UUID(),
        weight: Double? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil,
        inclinePercent: Double? = nil,
        speedKmh: Double? = nil,
        orderIndex: Int = 0,
        completedAt: Date? = nil,
        setType: String? = nil,
        rpe: Int? = nil,
        isAssisted: Bool? = false,
        setNote: String? = nil,
        workoutExercise: WorkoutExercise? = nil
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.inclinePercent = inclinePercent
        self.speedKmh = speedKmh
        self.orderIndex = orderIndex
        self.completedAt = completedAt
        self.setType = setType
        self.rpe = rpe
        self.isAssisted = isAssisted
        self.setNote = setNote
        self.workoutExercise = workoutExercise
    }

    /// volume = weight × reps。nil の場合は 0。正本は VolumeCalculator。
    var volume: Double {
        VolumeCalculator.volume(weight: weight, reps: reps)
    }
}
