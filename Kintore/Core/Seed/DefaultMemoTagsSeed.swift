// File: Core/Seed/DefaultMemoTagsSeed.swift

import Foundation
import SwiftData

enum DefaultMemoTagsSeed {

    struct TagRow {
        let id: String
        let label: String
        let category: String?
        let sortOrder: Int
    }

    static let rows: [TagRow] = [
        TagRow(id: "form_bad", label: "フォーム崩れ", category: nil, sortOrder: 0),
        TagRow(id: "left_right_diff", label: "左右差", category: nil, sortOrder: 1),
        TagRow(id: "tired", label: "疲労強い", category: nil, sortOrder: 2),
        TagRow(id: "sleepy", label: "睡眠不足", category: nil, sortOrder: 3),
        TagRow(id: "pain", label: "痛みあり", category: nil, sortOrder: 4),
        TagRow(id: "crowded", label: "混雑", category: nil, sortOrder: 5),
        TagRow(id: "waiting_equipment", label: "器具待ち", category: nil, sortOrder: 6),
        TagRow(id: "focused", label: "集中できた", category: nil, sortOrder: 7),
        TagRow(id: "pump", label: "パンプ強い", category: nil, sortOrder: 8),
    ]

    /// 既に MemoTag が 1 件でもあればスキップ。なければ全件 insert。
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<MemoTag>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if !existing.isEmpty { return }

        for row in rows {
            let tag = MemoTag(id: row.id, label: row.label, category: row.category, sortOrder: row.sortOrder)
            modelContext.insert(tag)
        }
        try? modelContext.save()
    }
}
