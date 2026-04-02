// File: Core/Seed/DefaultExercisesSeed.swift

import Foundation
import SwiftData

enum DefaultExercisesSeed {

    struct ExerciseRow {
        let name: String
        let bodyPart: String
        let equipment: String
        let defaultRestSeconds: Int?
        var exerciseKind: ExerciseKind = .strength
        /// 有酸素のみ。`nil` は距離＋時間の汎用入力。
        var cardioInputStyle: String? = nil
        var searchKeywords: String = ""
    }

    /// 初回のみ投入。`WorkoutStatsService.canonicalBodyParts` に沿って部位別に主要種目をそろえる。
    static let rows: [ExerciseRow] = [
        // MARK: 胸
        ExerciseRow(name: "ベンチプレス", bodyPart: "胸", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "ベンチ,BP,bench"),
        ExerciseRow(name: "インクラインベンチプレス", bodyPart: "胸", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "インクラインベンチ,incline"),
        ExerciseRow(name: "デクラインベンチプレス", bodyPart: "胸", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "デクライン,decline"),
        ExerciseRow(name: "ダンベルプレス", bodyPart: "胸", equipment: "ダンベル", defaultRestSeconds: 90, searchKeywords: "DBプレス"),
        ExerciseRow(name: "インクラインダンベルプレス", bodyPart: "胸", equipment: "ダンベル", defaultRestSeconds: 90),
        ExerciseRow(name: "チェストプレス", bodyPart: "胸", equipment: "マシン", defaultRestSeconds: 90),
        ExerciseRow(name: "ペックデック", bodyPart: "胸", equipment: "マシン", defaultRestSeconds: 60, searchKeywords: "ペックフライ"),
        ExerciseRow(name: "ダンベルフライ", bodyPart: "胸", equipment: "ダンベル", defaultRestSeconds: 60, searchKeywords: "フライ,fly"),
        ExerciseRow(name: "ケーブルクロスオーバー", bodyPart: "胸", equipment: "ケーブル", defaultRestSeconds: 60, searchKeywords: "クロスオーバー,フライ"),
        ExerciseRow(name: "ディップス", bodyPart: "胸", equipment: "自重", defaultRestSeconds: 90, searchKeywords: "ディップ,dip"),
        ExerciseRow(name: "プッシュアップ", bodyPart: "胸", equipment: "自重", defaultRestSeconds: 60, searchKeywords: "腕立て,push up"),

        // MARK: 背中
        ExerciseRow(name: "デッドリフト", bodyPart: "背中", equipment: "バーベル", defaultRestSeconds: 120, searchKeywords: "デッド,DL,deadlift"),
        ExerciseRow(name: "ルーマニアンデッドリフト", bodyPart: "背中", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "RDL,ルーマニアン"),
        ExerciseRow(name: "懸垂", bodyPart: "背中", equipment: "自重", defaultRestSeconds: 90, searchKeywords: "チンアップ,pull up,chin"),
        ExerciseRow(name: "ラットプルダウン", bodyPart: "背中", equipment: "マシン", defaultRestSeconds: 90, searchKeywords: "ラット,lat pulldown"),
        ExerciseRow(name: "シーテッドロー", bodyPart: "背中", equipment: "マシン", defaultRestSeconds: 90, searchKeywords: "シーテッド,ローイング"),
        ExerciseRow(name: "Tバーロー", bodyPart: "背中", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "Tバー"),
        ExerciseRow(name: "バーベルロー", bodyPart: "背中", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "ベントオーバー,bent over"),
        ExerciseRow(name: "ダンベルロー", bodyPart: "背中", equipment: "ダンベル", defaultRestSeconds: 90, searchKeywords: "片手ロー,ワンハンド"),
        ExerciseRow(name: "ワンアームダンベルロー", bodyPart: "背中", equipment: "ダンベル", defaultRestSeconds: 90),
        ExerciseRow(name: "ケーブルロー", bodyPart: "背中", equipment: "ケーブル", defaultRestSeconds: 90),
        ExerciseRow(name: "フェイスプル", bodyPart: "背中", equipment: "ケーブル", defaultRestSeconds: 60, searchKeywords: "フェイスプル,リアデルト"),
        ExerciseRow(name: "シュラッグ", bodyPart: "背中", equipment: "ダンベル", defaultRestSeconds: 60, searchKeywords: "トラップ,聳肩"),

        // MARK: 脚
        ExerciseRow(name: "スクワット", bodyPart: "脚", equipment: "バーベル", defaultRestSeconds: 120, searchKeywords: "スクワット,スクワ,squat"),
        ExerciseRow(name: "フロントスクワット", bodyPart: "脚", equipment: "バーベル", defaultRestSeconds: 120, searchKeywords: "フロントスクワット"),
        ExerciseRow(name: "ハックスクワット", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 90, searchKeywords: "ハック"),
        ExerciseRow(name: "レッグプレス", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 90),
        ExerciseRow(name: "ブルガリアンスクワット", bodyPart: "脚", equipment: "ダンベル", defaultRestSeconds: 90, searchKeywords: "ブルガリアン,片脚"),
        ExerciseRow(name: "ランジ", bodyPart: "脚", equipment: "ダンベル", defaultRestSeconds: 90, searchKeywords: "突き,lunge"),
        ExerciseRow(name: "ステップアップ", bodyPart: "脚", equipment: "ダンベル", defaultRestSeconds: 90),
        ExerciseRow(name: "ヒップスラスト", bodyPart: "脚", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "ヒップスラ,臀筋"),
        ExerciseRow(name: "レッグカール", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 60, searchKeywords: "ハム,腿裏"),
        ExerciseRow(name: "レッグエクステンション", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 60, searchKeywords: "大腿四頭"),
        ExerciseRow(name: "ヒップアブダクション", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 60, searchKeywords: "外転"),
        ExerciseRow(name: "ヒップアダクション", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 60, searchKeywords: "内転"),
        ExerciseRow(name: "スタンディングカーフレイズ", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 45, searchKeywords: "ふくらはぎ,カーフ"),
        ExerciseRow(name: "シーテッドカーフレイズ", bodyPart: "脚", equipment: "マシン", defaultRestSeconds: 45),

        // MARK: 肩
        ExerciseRow(name: "ショルダープレス", bodyPart: "肩", equipment: "バーベル", defaultRestSeconds: 90, searchKeywords: "オーバーヘッドプレス,OHP"),
        ExerciseRow(name: "ダンベルショルダープレス", bodyPart: "肩", equipment: "ダンベル", defaultRestSeconds: 90),
        ExerciseRow(name: "アーノルドプレス", bodyPart: "肩", equipment: "ダンベル", defaultRestSeconds: 90, searchKeywords: "アーノルド"),
        ExerciseRow(name: "サイドレイズ", bodyPart: "肩", equipment: "ダンベル", defaultRestSeconds: 60, searchKeywords: "ラテラル,サイド"),
        ExerciseRow(name: "フロントレイズ", bodyPart: "肩", equipment: "ダンベル", defaultRestSeconds: 60),
        ExerciseRow(name: "リアデルトフライ", bodyPart: "肩", equipment: "ダンベル", defaultRestSeconds: 60, searchKeywords: "リア,リバースフライ"),
        ExerciseRow(name: "アップライトロウ", bodyPart: "肩", equipment: "バーベル", defaultRestSeconds: 60, searchKeywords: "アップライト"),

        // MARK: 腕
        ExerciseRow(name: "バーベルカール", bodyPart: "腕", equipment: "バーベル", defaultRestSeconds: 60),
        ExerciseRow(name: "アームカール", bodyPart: "腕", equipment: "ダンベル", defaultRestSeconds: 60, searchKeywords: "ダンベルカール"),
        ExerciseRow(name: "ハンマーカール", bodyPart: "腕", equipment: "ダンベル", defaultRestSeconds: 60),
        ExerciseRow(name: "プリーチャーカール", bodyPart: "腕", equipment: "バーベル", defaultRestSeconds: 60, searchKeywords: "プリーチャー"),
        ExerciseRow(name: "トライセプスプレスダウン", bodyPart: "腕", equipment: "ケーブル", defaultRestSeconds: 60, searchKeywords: "プレスダウン,三頭"),
        ExerciseRow(name: "スカルクラッシャー", bodyPart: "腕", equipment: "バーベル", defaultRestSeconds: 60, searchKeywords: "ライイング,三頭"),
        ExerciseRow(name: "オーバーヘッドエクステンション", bodyPart: "腕", equipment: "ダンベル", defaultRestSeconds: 60, searchKeywords: "フレンチプレス,三頭"),

        // MARK: 体幹
        ExerciseRow(name: "クランチ", bodyPart: "体幹", equipment: "自重", defaultRestSeconds: 45),
        ExerciseRow(name: "プランク", bodyPart: "体幹", equipment: "自重", defaultRestSeconds: 45, exerciseKind: .time),
        ExerciseRow(name: "ケーブルクランチ", bodyPart: "体幹", equipment: "ケーブル", defaultRestSeconds: 45),
        ExerciseRow(name: "ハンギングレッグレイズ", bodyPart: "体幹", equipment: "自重", defaultRestSeconds: 60, searchKeywords: "レッグレイズ,腹"),
        ExerciseRow(name: "ロシアンツイスト", bodyPart: "体幹", equipment: "自重", defaultRestSeconds: 45),
        ExerciseRow(name: "アブローラー", bodyPart: "体幹", equipment: "自重", defaultRestSeconds: 60, searchKeywords: "腹筋ローラー"),

        // MARK: 有酸素（距離＋時間の汎用。トレッドのランニング等は `TreadmillCardioExercisesSeed` で別途）
        ExerciseRow(
            name: "エアロバイク",
            bodyPart: "有酸素",
            equipment: "バイク",
            defaultRestSeconds: 60,
            exerciseKind: .cardio,
            searchKeywords: "エアロ,バイク,Assault"
        ),
        ExerciseRow(
            name: "ローイングマシン",
            bodyPart: "有酸素",
            equipment: "ローアー",
            defaultRestSeconds: 60,
            exerciseKind: .cardio,
            searchKeywords: "ローイング,Concept2,エルゴ"
        ),
        ExerciseRow(
            name: "エリプティカル",
            bodyPart: "有酸素",
            equipment: "マシン",
            defaultRestSeconds: 60,
            exerciseKind: .cardio,
            searchKeywords: "クロストレーナー"
        ),
    ]

    /// 同名の種目が無いプリセットだけを追加する（冪等）。トレッドのみ先に入っている端末でも筋トレ系が追加入る。
    static func upsertMissingPresets(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        var names = Set(existing.map(\.name))
        var nextSort = existing.map(\.sortOrder).max() ?? -1

        var inserted = false
        for row in rows {
            if names.contains(row.name) { continue }
            nextSort += 1
            let exercise = Exercise(
                name: row.name,
                bodyPartTag: row.bodyPart,
                equipmentTag: row.equipment,
                defaultRestSeconds: row.defaultRestSeconds,
                exerciseKind: row.exerciseKind.rawValue,
                cardioInputStyle: row.cardioInputStyle,
                searchKeywords: row.searchKeywords,
                isPreset: true,
                isFavorite: false,
                sortOrder: nextSort,
                createdAt: Date()
            )
            modelContext.insert(exercise)
            names.insert(row.name)
            inserted = true
        }
        if inserted {
            try? modelContext.save()
        }
    }
}
