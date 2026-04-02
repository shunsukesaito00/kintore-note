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
    /// ウォームアップセット用の休憩秒数。nil の場合は本番用 defaultRestSeconds または 60 を使う。
    var defaultRestSecondsWarmUp: Int?
    /// `ExerciseKind` の rawValue。未設定・旧データは strength として扱う。
    var exerciseKind: String = ExerciseKind.strength.rawValue
    /// 有酸素の入力レイアウト。`CardioInputStyle` の rawValue。nil は距離＋時間。
    var cardioInputStyle: String?
    /// 検索用の別名・通称。カンマ区切り（例: `ベンチ,BP,bench press`）。
    var searchKeywords: String = ""
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
        defaultRestSecondsWarmUp: Int? = nil,
        exerciseKind: String = ExerciseKind.strength.rawValue,
        cardioInputStyle: String? = nil,
        searchKeywords: String = "",
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
        self.defaultRestSecondsWarmUp = defaultRestSecondsWarmUp
        self.exerciseKind = exerciseKind
        self.cardioInputStyle = cardioInputStyle
        self.searchKeywords = searchKeywords
        self.isPreset = isPreset
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
