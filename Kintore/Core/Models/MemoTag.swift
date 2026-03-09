// File: Core/Models/MemoTag.swift
// 初版は固定タグ。id は文字列で "form_bad", "pain" 等。

import Foundation
import SwiftData

@Model
final class MemoTag {
    @Attribute(.unique) var id: String
    var label: String
    var category: String?
    var sortOrder: Int

    init(id: String, label: String, category: String? = nil, sortOrder: Int = 0) {
        self.id = id
        self.label = label
        self.category = category
        self.sortOrder = sortOrder
    }
}
