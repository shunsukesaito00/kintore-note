// File: Core/Services/RestTimerManager.swift
// 休憩タイマー: 目標終了時刻を UserDefaults に保持し、復帰時に再計算。ローカル通知を1回スケジュール。

import Foundation
import UserNotifications

private let restTargetEndDateKey = "kintore.restTimer.targetEndDate"
private let restNotificationId = "kintore.rest.end"

@Observable
final class RestTimerManager {
    private let userDefaults: UserDefaults
    private var timer: Timer?
    private var _remainingSeconds: Int = 0

    /// 残り秒数（0 で休憩終了）。1秒ごとに更新される。
    var remainingSeconds: Int {
        get { _remainingSeconds }
        set { _remainingSeconds = max(0, newValue) }
    }

    var isResting: Bool { remainingSeconds > 0 }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        restoreFromUserDefaults()
    }

    deinit {
        timer?.invalidate()
    }

    /// 休憩開始。既存の休憩は上書き。
    func startRest(seconds: Int) {
        let target = Date().addingTimeInterval(TimeInterval(seconds))
        userDefaults.set(target.timeIntervalSince1970, forKey: restTargetEndDateKey)
        remainingSeconds = seconds
        scheduleNotification(at: target)
        startTickTimer()
    }

    /// 休憩スキップ
    func skipRest() {
        cancelNotification()
        userDefaults.removeObject(forKey: restTargetEndDateKey)
        timer?.invalidate()
        timer = nil
        remainingSeconds = 0
    }

    /// 休憩を延長
    func extendRest(seconds: Int) {
        let currentTarget = targetEndDate ?? Date()
        let newTarget = currentTarget.addingTimeInterval(TimeInterval(seconds))
        userDefaults.set(newTarget.timeIntervalSince1970, forKey: restTargetEndDateKey)
        remainingSeconds = max(0, Int(newTarget.timeIntervalSince(Date())))
        scheduleNotification(at: newTarget)
    }

    /// アプリ復帰時などに呼び、UserDefaults から目標時刻を読み直して残りを再計算する。
    func restoreFromUserDefaults() {
        guard let target = targetEndDate else {
            remainingSeconds = 0
            return
        }
        let remaining = Int(target.timeIntervalSince(Date()))
        if remaining <= 0 {
            userDefaults.removeObject(forKey: restTargetEndDateKey)
            cancelNotification()
            remainingSeconds = 0
        } else {
            remainingSeconds = remaining
            startTickTimer()
        }
    }

    private var targetEndDate: Date? {
        let t = userDefaults.double(forKey: restTargetEndDateKey)
        guard t > 0 else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    private func startTickTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        guard let target = targetEndDate else {
            remainingSeconds = 0
            timer?.invalidate()
            timer = nil
            return
        }
        let remaining = Int(target.timeIntervalSince(Date()))
        if remaining <= 0 {
            userDefaults.removeObject(forKey: restTargetEndDateKey)
            cancelNotification()
            timer?.invalidate()
            timer = nil
            remainingSeconds = 0
        } else {
            remainingSeconds = remaining
        }
    }

    private func scheduleNotification(at date: Date) {
        cancelNotification()
        let content = UNMutableNotificationContent()
        content.title = "休憩終了"
        content.body = "次のセットを始めましょう"
        content.sound = .default
        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: restNotificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restNotificationId])
    }

    /// 休憩開始前に呼ぶ。許可が未取得ならリクエストする。
    static func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            }
        }
    }
}
