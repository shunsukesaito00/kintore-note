// File: KintoreWatch/WatchSessionManager.swift
// Watch 側: iPhone から送られた休憩タイマー・種目名・PR を受信

import Foundation
import WatchConnectivity
import WatchKit

@Observable
final class WatchSessionManager: NSObject {
    var restRemainingSeconds: Int = 0
    var currentExerciseName: String?
    var isPremium: Bool = false
    /// 進行中セッションの直近 PR 表示用（iPhone から送られる）
    var lastPrText: String?

    @MainActor static let shared = WatchSessionManager()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        let ctx = s.receivedApplicationContext
        let rest = (ctx["rest"] as? Int) ?? 0
        let exercise = ctx["exercise"] as? String
        let premium = (ctx["premium"] as? Bool) ?? false
        let pr = ctx["pr"] as? String
        Task { @MainActor in
            WatchSessionManager.shared.applyReceivedValues(rest: rest, exercise: exercise, premium: premium, pr: pr)
        }
    }

    /// デリゲートから MainActor で更新する用。Sendable な値だけ渡してデータ競合を避ける。
    @MainActor private func applyReceivedValues(rest: Int, exercise: String?, premium: Bool, pr: String?) {
        restRemainingSeconds = rest
        currentExerciseName = exercise
        isPremium = premium
        lastPrText = pr
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            let ctx = session.receivedApplicationContext
            let rest = (ctx["rest"] as? Int) ?? 0
            let exercise = ctx["exercise"] as? String
            let premium = (ctx["premium"] as? Bool) ?? false
            let pr = ctx["pr"] as? String
            Task { @MainActor in
                WatchSessionManager.shared.applyReceivedValues(rest: rest, exercise: exercise, premium: premium, pr: pr)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let rest = (applicationContext["rest"] as? Int) ?? 0
        let exercise = applicationContext["exercise"] as? String
        let premium = (applicationContext["premium"] as? Bool) ?? false
        let pr = applicationContext["pr"] as? String
        Task { @MainActor in
            WatchSessionManager.shared.applyReceivedValues(rest: rest, exercise: exercise, premium: premium, pr: pr)
        }
    }

    /// Watch の「セット完了」ボタンから呼ぶ。iPhone にメッセージを送り、記録画面で先頭の未完了セットを完了にする。
    func sendSetComplete() {
        sendPayload(["action": "setComplete"], fallbackUserInfo: ["action": "setComplete"])
    }

    /// 重量（kg）・回数を送って先頭の未完了セットを完了。記録画面が iPhone で開いているときのみ反映される。
    func sendWeightRepsComplete(weightKg: Double, reps: Int) {
        let payload: [String: Any] = [
            "action": "setWeightRepsComplete",
            "weightKg": weightKg,
            "reps": reps
        ]
        sendPayload(payload, fallbackUserInfo: payload)
    }

    private func sendPayload(_ message: [String: Any], fallbackUserInfo: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: { reply in
                let success = (reply["ok"] as? Bool) == true
                Task { @MainActor in
                    if success {
                        WKInterfaceDevice.current().play(.success)
                    }
                }
            }, errorHandler: { _ in
                WCSession.default.transferUserInfo(fallbackUserInfo)
            })
        } else {
            WCSession.default.transferUserInfo(fallbackUserInfo)
        }
    }
}
