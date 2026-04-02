// File: Core/Utilities/AppFormatters.swift

import Foundation

enum AppFormatters {
    private static let weightNumberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

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
        formatWeight(value, unit: "kg")
    }

    /// 重量を表示用文字列に。単位は設定に合わせて呼び元で渡す。小数（0.5kg 等）を維持。
    static func formatWeight(_ value: Double?, unit: String) -> String {
        guard let v = value, v > 0 else { return "—" }
        return "\(formatWeightNumber(v)) \(unit)"
    }

    /// 重量の数値部分のみ（表の縦積み・一覧用）
    static func formatWeightNumericOnly(_ value: Double?) -> String {
        guard let v = value, v > 0 else { return "—" }
        return formatWeightNumber(v)
    }

    /// 整数なら Int 表記、小数なら最大2桁
    static func formatWeightNumber(_ value: Double) -> String {
        weightNumberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// kg → lb（表示用換算）
    static func kilogramsToPounds(_ kg: Double) -> Double {
        kg * 2.2046226218
    }

    /// lb → kg
    static func poundsToKilograms(_ lb: Double) -> Double {
        lb / 2.2046226218
    }

    static func formatDuration(seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)秒" }
        let m = seconds / 60
        let s = seconds % 60
        if s == 0 { return "\(m)分" }
        return "\(m)分\(s)秒"
    }

    /// ワークアウト開始画面の部位帯用：最終実施からの相対表現（ロケールに追従）
    static func formatRelativeWorkoutPast(from date: Date) -> String {
        let now = Date()
        if now.timeIntervalSince(date) < 90 {
            return String(localized: "relative_just_now")
        }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale.current
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: now)
    }

    /// ナビ用：今日の日付（例: 2026/03/21）
    static func formatNavBarDateToday() -> String {
        formatNavBarDate(Date())
    }

    /// ナビ用：任意日付（セッション開始日など）
    static func formatNavBarDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "yyyy/MM/dd"
        return f.string(from: date)
    }

    /// 時刻のみ（セッション開始・終了の表示用）
    static func formatShortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }
}
