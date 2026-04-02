// File: Core/Services/RetentionNotificationService.swift
// Phase 12: 再開リマインド・週次サマリ通知。頻度は控えめに。

import Foundation
import SwiftData
import UserNotifications

private let reengagementEnabledKey = "kintore.notification.reengagementEnabled"
private let weeklySummaryEnabledKey = "kintore.notification.weeklySummaryEnabled"
private let reengagementId = "kintore.reengagement"
private let weeklySummaryId = "kintore.weeklySummary"

enum RetentionNotificationService {
    static let reengagementDays = 3

    static var isReengagementEnabled: Bool {
        get { UserDefaults.standard.object(forKey: reengagementEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: reengagementEnabledKey) }
    }

    static var isWeeklySummaryEnabled: Bool {
        get { UserDefaults.standard.object(forKey: weeklySummaryEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: weeklySummaryEnabledKey) }
    }

    // MARK: - Authorization（設定画面・トグル ON 時）

    /// `UNNotificationSettings` 本体は Swift 6 で非 Sendable のため、判定に必要な値だけ返す。
    static func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                cont.resume(returning: settings.authorizationStatus)
            }
        }
    }

    /// アラート通知の許可を求める。設定でトグル ON 時に呼ぶ。
    static func requestAuthorizationForAlerts() async -> Bool {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                cont.resume(returning: granted)
            }
        }
    }

    static func cancelReengagementPending() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reengagementId])
    }

    /// セッション保存後に呼ぶ。3日後に再開リマインドを1本スケジュール（既存はキャンセル）
    static func scheduleReengagementIfNeeded() {
        guard isReengagementEnabled else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reengagementId])
        let content = UNMutableNotificationContent()
        content.title = pushNotificationTitle()
        content.body = reengagementBodyText(days: reengagementDays)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(reengagementDays * 24 * 3600), repeats: false)
        let request = UNNotificationRequest(identifier: reengagementId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func pushNotificationTitle() -> String {
        String(localized: "notification_push_title")
    }

    static func reengagementBodyText(days: Int = reengagementDays) -> String {
        String.localizedStringWithFormat(String(localized: "notification_reengagement_format"), days)
    }

    static func weeklySummaryBodyText(weekCount: Int) -> String {
        if weekCount == 0 {
            return String(localized: "notification_weekly_summary_zero")
        }
        return String.localizedStringWithFormat(String(localized: "notification_weekly_summary_count_format"), weekCount)
    }

    /// 週次サマリを **次の土曜 20:00** に1本スケジュール（非繰り返し）。本文に今週の実施回数を含める（Phase 12）。
    static func syncWeeklySummarySchedule(modelContext: ModelContext) {
        guard isWeeklySummaryEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [weeklySummaryId])
            return
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [weeklySummaryId])

        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return }
        let stats = WorkoutStatsService(modelContext: modelContext)
        let weekCount = (try? stats.workoutCount(from: weekStart, to: now)) ?? 0

        var saturday20 = DateComponents()
        saturday20.weekday = 7
        saturday20.hour = 20
        saturday20.minute = 0
        guard let fireDate = cal.nextDate(after: now, matching: saturday20, matchingPolicy: .nextTime) else { return }
        let triggerComponents = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = pushNotificationTitle()
        content.body = weeklySummaryBodyText(weekCount: weekCount)
        content.sound = .default
        let request = UNNotificationRequest(identifier: weeklySummaryId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
