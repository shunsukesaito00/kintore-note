// File: KintoreWidget/RepLogWidget.swift
// Phase 14: ホーム画面ウィジェット「今週○回」「直近PR」
// Xcode で Widget Extension ターゲットを追加し、App Group "group.com.shunsukesaito.kintore" を有効にしてください。

import WidgetKit
import SwiftUI

/// Phase 8/9: `AppTheme.accent`（ライト）＝ `WatchBrandColors.accent` と同じ RGB。変更時は3箇所を同期。
private let widgetAccentForeground = Color(red: 0.29, green: 0.56, blue: 0.85)

private let appGroupId = "group.com.shunsukesaito.kintore"
private let streakWeeksKey = "widget.streakWeeks"

struct RepLogWidgetEntry: TimelineEntry {
    let date: Date
    let weekCount: Int
    let latestPR: String?
    let streakWeeks: Int
}

struct RepLogWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RepLogWidgetEntry {
        RepLogWidgetEntry(
            date: Date(),
            weekCount: 3,
            latestPR: String(localized: "widget_placeholder_pr", bundle: .main),
            streakWeeks: 4
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RepLogWidgetEntry) -> Void) {
        let suite = UserDefaults(suiteName: appGroupId)
        let weekCount = suite?.integer(forKey: "widget.weekCount") ?? 0
        let latestPR = suite?.string(forKey: "widget.latestPR")
        let streakWeeks = suite?.integer(forKey: streakWeeksKey) ?? 0
        completion(RepLogWidgetEntry(date: Date(), weekCount: weekCount, latestPR: latestPR, streakWeeks: streakWeeks))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RepLogWidgetEntry>) -> Void) {
        let suite = UserDefaults(suiteName: appGroupId)
        let weekCount = suite?.integer(forKey: "widget.weekCount") ?? 0
        let latestPR = suite?.string(forKey: "widget.latestPR")
        let streakWeeks = suite?.integer(forKey: streakWeeksKey) ?? 0
        let entry = RepLogWidgetEntry(date: Date(), weekCount: weekCount, latestPR: latestPR, streakWeeks: streakWeeks)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct RepLogWidgetView: View {
    var entry: RepLogWidgetEntry

    private var hasAnyData: Bool {
        if entry.weekCount > 0 || entry.streakWeeks > 0 { return true }
        if let pr = entry.latestPR, !pr.isEmpty { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                    .foregroundStyle(widgetAccentForeground)
                Text(String(localized: "widget_week_title", bundle: .main))
                    .font(.caption.weight(.semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                if hasAnyData {
                    Text(String(format: String(localized: "widget_week_sessions", bundle: .main), entry.weekCount))
                        .font(.subheadline.weight(.medium))
                    if entry.streakWeeks > 0 {
                        Text(String(format: String(localized: "widget_streak_weeks", bundle: .main), entry.streakWeeks))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let pr = entry.latestPR, !pr.isEmpty {
                        Text(String(format: String(localized: "widget_latest_pr", bundle: .main), pr))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(String(localized: "widget_empty_hint", bundle: .main))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .widgetURL(URL(string: "kintore://home"))
    }
}

struct RepLogWidget: Widget {
    let kind: String = "RepLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RepLogWidgetProvider()) { entry in
            RepLogWidgetView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget_display_name", bundle: .main))
        .description(String(localized: "widget_description", bundle: .main))
    }
}

#Preview(as: .systemSmall) {
    RepLogWidget()
} timeline: {
    RepLogWidgetEntry(date: Date(), weekCount: 3, latestPR: String(localized: "widget_placeholder_pr", bundle: .main), streakWeeks: 4)
    RepLogWidgetEntry(date: Date(), weekCount: 0, latestPR: nil, streakWeeks: 0)
}
