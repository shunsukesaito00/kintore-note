// File: Core/Utilities/MemoTagIdsHelper.swift

import Foundation

enum MemoTagIdsHelper {
    /// カンマ区切り文字列 → [String]。空文字は空配列。
    static func parse(_ string: String) -> [String] {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }
        return trimmed.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// [String] → カンマ区切り文字列
    static func serialize(_ ids: [String]) -> String {
        ids.joined(separator: ",")
    }
}
