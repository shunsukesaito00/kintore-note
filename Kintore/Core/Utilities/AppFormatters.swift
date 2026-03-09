// File: Core/Utilities/AppFormatters.swift

import Foundation

enum AppFormatters {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    private static let dateWithWeekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d(E)"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    static func formatDate(_ date: Date) -> String { dateFormatter.string(from: date) }
    static func formatDateWithWeekday(_ date: Date) -> String { dateWithWeekday.string(from: date) }

    static func formatWeight(_ value: Double?) -> String {
        guard let v = value, v > 0 else { return "—" }
        return "\(Int(v))kg"
    }

    static func formatDuration(seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)秒" }
        let m = seconds / 60
        let s = seconds % 60
        if s == 0 { return "\(m)分" }
        return "\(m)分\(s)秒"
    }
}
