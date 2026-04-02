// File: Core/Services/HealthKitWorkoutService.swift
// 完了ワークアウトをヘルスケアに保存する最小実装（筋力トレーニング）。

import Foundation
import HealthKit

enum HealthKitSettings {
    static let saveWorkoutsKey = "kintore.healthkit.saveWorkoutsToHealth"
    private static let lastSaveErrorKey = "kintore.healthkit.lastSaveError"
    private static let pendingSummaryAlertKey = "kintore.healthkit.pendingSummaryAlert"

    static var saveWorkoutsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: saveWorkoutsKey) }
        set { UserDefaults.standard.set(newValue, forKey: saveWorkoutsKey) }
    }

    /// 直近のワークアウト保存失敗（設定画面に表示）。成功時はクリアする。
    static var lastSaveErrorMessage: String? {
        UserDefaults.standard.string(forKey: lastSaveErrorKey)
    }

    /// セッション完了サマリーで一度だけヘルスケア保存失敗を伝えるためのフラグ。
    static var shouldShowHealthSaveErrorOnSummary: Bool {
        UserDefaults.standard.bool(forKey: pendingSummaryAlertKey)
    }

    static func clearLastSaveError() {
        UserDefaults.standard.removeObject(forKey: lastSaveErrorKey)
        UserDefaults.standard.set(false, forKey: pendingSummaryAlertKey)
    }

    static func acknowledgeHealthSaveErrorOnSummary() {
        UserDefaults.standard.set(false, forKey: pendingSummaryAlertKey)
    }

    fileprivate static func recordSaveError(_ error: Error) {
        UserDefaults.standard.set(error.localizedDescription, forKey: lastSaveErrorKey)
        UserDefaults.standard.set(true, forKey: pendingSummaryAlertKey)
    }
}

/// ワークアウトの書き込みのみ（読み取りは行わない）。
final class HealthKitWorkoutService: @unchecked Sendable {
    static let shared = HealthKitWorkoutService()

    private let store = HKHealthStore()

    private init() {}

    /// ヘルスケアが利用可能な端末か（シミュレータは制限あり）。
    static var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// ワークアウト保存の許可を求める。設定でトグル ON 時に呼ぶ。
    func requestAuthorizationIfNeeded() async {
        guard Self.isHealthDataAvailable else { return }
        let workoutType = HKObjectType.workoutType()
        do {
            try await store.requestAuthorization(toShare: [workoutType], read: [])
        } catch {
            #if DEBUG
            print("[HealthKit] authorization: \(error.localizedDescription)")
            #endif
        }
    }

    /// 設定が ON のとき、筋トレとしてワークアウトを保存する。
    func saveWorkoutIfEnabled(start: Date, end: Date) async {
        guard HealthKitSettings.saveWorkoutsEnabled else { return }
        guard Self.isHealthDataAvailable else { return }
        let safeEnd = max(end, start.addingTimeInterval(60))
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: start,
            end: safeEnd
        )
        do {
            try await store.save(workout)
            HealthKitSettings.clearLastSaveError()
        } catch {
            HealthKitSettings.recordSaveError(error)
            #if DEBUG
            print("[HealthKit] save workout: \(error.localizedDescription)")
            #endif
        }
    }
}
