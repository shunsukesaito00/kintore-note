// File: Core/Services/WatchSyncManager.swift
// iPhone → Watch 休憩タイマー同期（WatchConnectivity）

import Foundation
import WatchConnectivity

#if os(iOS)
/// iPhone 側: WCSession を有効化し、休憩残り秒数・種目名を Watch に送る。
final class WatchSyncManager: NSObject, @unchecked Sendable {
    static let shared = WatchSyncManager()

    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    /// 休憩状態を Watch に送信。remaining が 0 のときは休憩なし。プレミアム状態・PR テキストも送る。
    func updateRest(remaining: Int, exerciseName: String?, lastPrText: String? = nil) {
        guard let session = session, session.activationState == .activated else { return }
        var ctx: [String: Any] = [
            "rest": remaining,
            "premium": PremiumService.cachedIsPremium
        ]
        if let name = exerciseName, !name.isEmpty {
            ctx["exercise"] = name
        }
        if let pr = lastPrText, !pr.isEmpty {
            ctx["pr"] = pr
        }
        try? session.updateApplicationContext(ctx)
    }
}

extension WatchSyncManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    /// Watch の「セット完了」または「重量・回数を送って完了」受信。
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        switch message["action"] as? String {
        case "setComplete":
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: WatchSyncManager.setCompleteRequestNotification, object: nil)
            }
            replyHandler(["ok": true])
        case "setWeightRepsComplete":
            let w = Self.extractDouble(message["weightKg"]) ?? 0
            let r = message["reps"] as? Int ?? (message["reps"] as? NSNumber)?.intValue ?? 0
            guard w > 0, r > 0 else {
                replyHandler(["ok": false, "error": "invalid"])
                return
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: WatchSyncManager.weightRepsCompleteRequestNotification,
                    object: nil,
                    userInfo: ["weightKg": w, "reps": r]
                )
            }
            replyHandler(["ok": true])
        default:
            replyHandler([:])
        }
    }

    /// `sendMessage` が届かない場合の `transferUserInfo` 受信。
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        switch userInfo["action"] as? String {
        case "setComplete":
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: WatchSyncManager.setCompleteRequestNotification, object: nil)
            }
        case "setWeightRepsComplete":
            let w = Self.extractDouble(userInfo["weightKg"]) ?? 0
            let r = userInfo["reps"] as? Int ?? (userInfo["reps"] as? NSNumber)?.intValue ?? 0
            guard w > 0, r > 0 else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: WatchSyncManager.weightRepsCompleteRequestNotification,
                    object: nil,
                    userInfo: ["weightKg": w, "reps": r]
                )
            }
        default:
            break
        }
    }

    private static func extractDouble(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let n = value as? NSNumber { return n.doubleValue }
        return nil
    }
}

extension WatchSyncManager {
    static let setCompleteRequestNotification = Notification.Name("WatchSyncManager.setCompleteRequest")
    /// userInfo: `weightKg` (Double), `reps` (Int)。記録画面が前面のときのみ ViewModel が処理する。
    static let weightRepsCompleteRequestNotification = Notification.Name("WatchSyncManager.weightRepsComplete")
}
#endif
