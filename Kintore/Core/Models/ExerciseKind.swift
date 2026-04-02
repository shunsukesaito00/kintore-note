// File: Core/Models/ExerciseKind.swift
// 種目タイプ（筋トレ / 時間 / 有酸素 / 加重自体重）。永続化は rawValue 文字列。

import Foundation

enum ExerciseKind: String, CaseIterable, Identifiable {
    case strength = "strength"
    /// プランク等。セットは秒数（durationSeconds）のみ。
    case time = "time"
    /// ランニング等。距離（m）と任意で時間（秒）。
    case cardio = "cardio"
    /// ディップス加重など。重量×回＋補助。PR は strength と同様。
    case weightedBodyweight = "weightedBodyweight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return String(localized: "exercise_kind_strength")
        case .time: return String(localized: "exercise_kind_time")
        case .cardio: return String(localized: "exercise_kind_cardio")
        case .weightedBodyweight: return String(localized: "exercise_kind_weighted_bodyweight")
        }
    }

    /// 総挙上（ボリューム）に重量×回を使うか。
    var usesLoadVolume: Bool {
        switch self {
        case .strength, .weightedBodyweight: return true
        case .time, .cardio: return false
        }
    }

    /// PR（1RM 相当の重量×回）を更新するか。
    var participatesInPersonalRecord: Bool {
        switch self {
        case .strength, .weightedBodyweight: return true
        case .time, .cardio: return false
        }
    }

    init(stored: String?) {
        if let s = stored, let k = ExerciseKind(rawValue: s) {
            self = k
        } else {
            self = .strength
        }
    }
}

/// 有酸素の入力 UI 種別。`Exercise.cardioInputStyle` に rawValue で保存。
enum CardioInputStyle: String {
    /// トレッドミル: 傾斜・速度・時間
    case treadmill = "treadmill"
}
