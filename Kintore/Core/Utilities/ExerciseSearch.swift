// File: Core/Utilities/ExerciseSearch.swift
// 種目名・部位・器具・別名（カンマ区切り）による検索マッチ。

import Foundation

enum ExerciseSearch {
    /// `keyword` が空なら常に true（呼び出し側で全件表示）。
    static func matches(_ exercise: Exercise, keyword: String) -> Bool {
        let k = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return true }
        if exercise.name.localizedCaseInsensitiveContains(k) { return true }
        if !exercise.bodyPartTag.isEmpty, exercise.bodyPartTag.localizedCaseInsensitiveContains(k) {
            return true
        }
        if !exercise.equipmentTag.isEmpty, exercise.equipmentTag.localizedCaseInsensitiveContains(k) {
            return true
        }
        for part in exercise.searchKeywords.split(separator: ",") {
            let t = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            if t.localizedCaseInsensitiveContains(k) || k.localizedCaseInsensitiveContains(t) {
                return true
            }
        }
        return false
    }
}
