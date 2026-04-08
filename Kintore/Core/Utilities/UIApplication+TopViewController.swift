// File: Core/Utilities/UIApplication+TopViewController.swift
// 広告のクリック遷移用に最前面の UIViewController を取得する。

import UIKit

extension UIApplication {
    /// キーウィンドウから最前面の表示中 VC を返す（広告 SDK の rootViewController 用）。
    static func kintore_topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        return topViewController(from: keyWindow?.rootViewController)
    }

    private static func topViewController(from base: UIViewController?) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(from: presented)
        }
        return base
    }
}
