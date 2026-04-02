// File: Core/Utilities/AppDeepLinkHandler.swift
// カスタム URL スキーム（ウィジェット等）からタブを切り替える

import Foundation

enum AppDeepLinkHandler {
    /// `MainTabView` と共有。UserDefaults 経由でウィジェット起動時にタブを切り替える。
    static let mainTabIndexStorageKey = "kintore.mainTabIndex"

    /// ウィジェットの `widgetURL` 用（メインターゲット外でも同じ文字列を使う）
    static let widgetEntryURLString = "kintore://home"

    /// `kintore://` または `kintore:` を解釈し、該当タブ index を保存する。
    static func apply(_ url: URL) {
        guard url.scheme?.lowercased() == "kintore" else { return }

        let host = (url.host ?? "").lowercased()
        let pathFirst = url.pathComponents.first { $0 != "/" }
        let segment: String
        if !host.isEmpty, host != "/" {
            segment = host
        } else {
            segment = (pathFirst ?? "").lowercased()
        }

        let tab: Int
        switch segment {
        case "", "home":
            tab = 0
        case "history":
            tab = 1
        case "statistics", "stats":
            tab = 2
        case "settings":
            tab = 3
        default:
            tab = 0
        }
        UserDefaults.standard.set(tab, forKey: mainTabIndexStorageKey)
    }
}
