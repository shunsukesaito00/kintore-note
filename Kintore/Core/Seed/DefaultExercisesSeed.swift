// File: Core/Seed/DefaultExercisesSeed.swift

import Foundation
import SwiftData

enum DefaultExercisesSeed {

    struct ExerciseRow {
        let name: String
        let bodyPart: String
        let equipment: String
        let defaultRestSeconds: Int?
    }

    static let rows: [ExerciseRow] = [
        ExerciseRow(name: "ベンチプレス", bodyPart: "胸", equipment: "バーベル", defaultRestSeconds: 90),
        ExerciseRow(name: "スクワット", bodyPart: "脚", equipment: "バーベル", defaultRestSeconds: 120),
        ExerciseRow(name: "デッドリフト", bodyPart: "背中", equipment: "バーベル", defaultRestSeconds: 120),
        ExerciseRow(name: "ショルダープレス", bodyPart: "肩", equipment: "バーベル", defaultRestSeconds: 90),
        ExerciseRow(name: "ラットプルダウン", bodyPart: "背中", equipment: "マシン", defaultRestSeconds: 90),
        ExerciseRow(name: "ダンベルロー", bodyPart: "背中", equipment: "ダンベル", defaultRestSeconds: 90),
        ExerciseRow(name: "レッグプレス", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 90),
        ExerciseRow(name: "レッグカール", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 60),
        ExerciseRow(name: "レッグエクステンション", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 60),
        ExerciseRow(name: "チェストプレス", bodyPart: "胸", equipment: "マシン", defaultRestSeconds: 90),
        ExerciseRow(name: "インクラインダンベルプレス", bodyPart: "胸", equipment: "ダンベル", defaultRestSeconds: 90),
        ExerciseRow(name: "サイドレイズ", bodyPart: "肩", equipment: "ダンベル", defaultRestSeconds: 60),
        ExerciseRow(name: "アームカール", bodyPart: "腕", equipment: "ダンベル", defaultRestSeconds: 60),
        ExerciseRow(name: "トライセプスプレスダウン", bodyPart: "腕", equipment: "ケーブル", defaultRestSeconds: 60),
        ExerciseRow(name: "クランチ", bodyPart: "体幹", equipment: "自重", defaultRestSeconds: 45),
        ExerciseRow(name: "プランク", bodyPart: "体幹", equipment: "自重", defaultRestSeconds: 45),
        ExerciseRow(name: "ヒップスラスト", bodyPart: "脚", equipment: "バーベル", defaultRestSeconds: 90),
        ExerciseRow(name: "ブルガリアンスクワット", bodyPart: "脚", equipment: "ダンベル", defaultRestSeconds: 90),
        ExerciseRow(name: "懸垂", bodyPart: "背中", equipment: "自重", defaultRestSeconds: 90),
        ExerciseRow(name: "ペックデック", bodyPart: "胸", equipment: "マシン", defaultRestSeconds: 60),
        ExerciseRow(name: "インクラインベンチプレス", bodyPart: "胸", equipment: "バーベル", defaultRestSeconds: 90),
        ExerciseRow(name: "フロントレイズ", bodyPart: "肩", equipment: "ダンベル", defaultRestSeconds: 60),
    ]

    /// 既に種目が 1 件でもあればスキップ。なければ全件 insert。
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if !existing.isEmpty { return }

        for (index, row) in rows.enumerated() {
            let exercise = Exercise(
                name: row.name,
                bodyPartTag: row.bodyPart,
                equipmentTag: row.equipment,
                defaultRestSeconds: row.defaultRestSeconds,
                isPreset: true,
                isFavorite: false,
                sortOrder: index,
                createdAt: Date()
            )
            modelContext.insert(exercise)
        }
        try? modelContext.save()
    }
}
