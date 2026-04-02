// File: Core/Utilities/WatchSettingsHelper.swift
// 設定画面用: Apple Watch 連携の状態説明（WCSession）

#if os(iOS)
import Foundation
import WatchConnectivity

enum WatchSettingsHelper {
    static var footerText: String {
        guard WCSession.isSupported() else {
            return String(localized: "settings_watch_footer_unsupported")
        }
        let s = WCSession.default
        switch s.activationState {
        case .notActivated:
            return String(localized: "settings_watch_footer_connecting")
        case .inactive:
            return String(localized: "settings_watch_footer_inactive")
        case .activated:
            break
        @unknown default:
            return String(localized: "settings_watch_footer_connecting")
        }
        if !s.isPaired {
            return String(localized: "settings_watch_footer_not_paired")
        }
        if !s.isWatchAppInstalled {
            return String(localized: "settings_watch_footer_install_watch_app")
        }
        return String(localized: "settings_watch_footer_ready")
    }
}
#endif
