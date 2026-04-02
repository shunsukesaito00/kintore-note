// File: Core/Seed/TreadmillCardioExercisesSeed.swift
// 既存ユーザー向け: ランニング・ジョッギング（トレッドミル有酸素）を UUID 固定で upsert。

import Foundation
import SwiftData

enum TreadmillCardioExercisesSeed {

    /// 同一 ID で再投入・更新する（重複作成防止）
    static let runningExerciseId = UUID(uuidString: "E0B6C2A1-0001-4000-8000-000000000101")!
    static let joggingExerciseId = UUID(uuidString: "E0B6C2A1-0001-4000-8000-000000000102")!

    private static let rows: [(id: UUID, name: String, sortOrder: Int, searchKeywords: String)] = [
        (runningExerciseId, "ランニング", 10_000, "ラン,run,ランニングマシン,トレッドミル"),
        (joggingExerciseId, "ジョッギング", 10_001, "ジョグ,jog,慢跑"),
    ]

    /// 起動時に毎回呼んでもよい（存在すれば上書き更新のみ）。
    static func upsertIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        let byId = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

        for row in rows {
            if let existing = byId[row.id] {
                existing.name = row.name
                existing.bodyPartTag = "有酸素"
                existing.equipmentTag = "トレッドミル"
                existing.exerciseKind = ExerciseKind.cardio.rawValue
                existing.cardioInputStyle = CardioInputStyle.treadmill.rawValue
                existing.defaultRestSeconds = 60
                existing.isPreset = true
                existing.searchKeywords = row.searchKeywords
                if existing.sortOrder < row.sortOrder {
                    existing.sortOrder = row.sortOrder
                }
            } else {
                let ex = Exercise(
                    id: row.id,
                    name: row.name,
                    bodyPartTag: "有酸素",
                    equipmentTag: "トレッドミル",
                    defaultRestSeconds: 60,
                    exerciseKind: ExerciseKind.cardio.rawValue,
                    cardioInputStyle: CardioInputStyle.treadmill.rawValue,
                    searchKeywords: row.searchKeywords,
                    isPreset: true,
                    isFavorite: false,
                    sortOrder: row.sortOrder,
                    createdAt: Date()
                )
                modelContext.insert(ex)
            }
        }
        try? modelContext.save()
    }
}
