// File: Modules/Exercise/ExercisePickerViewModel.swift
// 種目ピッカー: 全種目取得・部位グループ・最終実施日

import Foundation
import SwiftData

@Observable
final class ExercisePickerViewModel {
    var exercises: [Exercise] = []
    /// 種目 ID → 最終実施日（完了セッション基準）
    var lastPerformedDates: [UUID: Date] = [:]
    var isLoading = false
    var errorMessage: String?

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol?

    init(exerciseRepository: ExerciseRepositoryProtocol, workoutRepository: WorkoutRepositoryProtocol? = nil) {
        self.exerciseRepository = exerciseRepository
        self.workoutRepository = workoutRepository
    }

    func load() {
        isLoading = true
        errorMessage = nil
        do {
            exercises = try exerciseRepository.fetchAllExercises()
            if let wr = workoutRepository {
                let ids = exercises.map(\.id)
                lastPerformedDates = try wr.fetchLastPerformedDates(for: ids)
            } else {
                lastPerformedDates = [:]
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 空部位のグループキー（表示は `displayBodyPartLabel` を使う）
    static let emptyBodyPartGroupKey = "__body_part_empty__"

    /// 部位タグでグループ化（空タグは専用キー）。部位名でソート。
    func groupedExercises(filtered exercises: [Exercise]) -> [(bodyPart: String, exercises: [Exercise])] {
        let groups = Dictionary(grouping: exercises) { ex -> String in
            let tag = ex.bodyPartTag.trimmingCharacters(in: .whitespacesAndNewlines)
            return tag.isEmpty ? Self.emptyBodyPartGroupKey : tag
        }
        return groups.keys.sorted { $0.localizedCompare($1) == .orderedAscending }.map { key in
            let list = (groups[key] ?? []).sorted { e1, e2 in
                if e1.isFavorite != e2.isFavorite { return e1.isFavorite }
                return (e1.sortOrder, e1.name) < (e2.sortOrder, e2.name)
            }
            return (bodyPart: key, exercises: list)
        }
    }

    static func displayBodyPartLabel(for groupKey: String) -> String {
        if groupKey == emptyBodyPartGroupKey {
            return String(localized: "exercise_body_part_other")
        }
        return groupKey
    }

    /// グループ内の「最終実施」の最新日時（いずれの種目も未実施なら nil）
    func latestDate(in exercises: [Exercise]) -> Date? {
        exercises.compactMap { lastPerformedDates[$0.id] }.max()
    }

    /// 新種目を保存し、一覧を再読込して作成した種目を返す。呼び出し元で onSelect(returned) してよい。
    func insertNewExercise(name: String, bodyPart: String, equipment: String, exerciseKind: ExerciseKind = .strength) throws -> Exercise {
        let count = (try? exerciseRepository.fetchAllExercises().count) ?? 0
        var cardio: String?
        if exerciseKind == .cardio {
            cardio = CardioInputStyle.treadmill.rawValue
        }
        let ex = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            bodyPartTag: bodyPart,
            equipmentTag: equipment,
            defaultRestSeconds: 90,
            exerciseKind: exerciseKind.rawValue,
            cardioInputStyle: cardio,
            isPreset: false,
            isFavorite: false,
            sortOrder: count,
            createdAt: Date()
        )
        try exerciseRepository.insertExercise(ex)
        load()
        return ex
    }
}
