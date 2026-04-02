// File: Core/Services/AnalyticsEventService.swift
// Phase 11: 分析基盤用イベントフック。Firebase / TelemetryDeck 等に接続する場合は同じ event 名で送信する。

import Foundation
import os

enum AnalyticsEvent {
    case appLaunch(isFirstLaunch: Bool)
    case sessionCompleted(sessionId: UUID)
    case premiumPurchased
    case onboardingCompleted
    case notificationPermissionGranted
    /// ウィジェット等の `kintore://` 起動
    case deepLinkOpened(url: URL)
    /// 統計タブの画面表示
    case statisticsScreenViewed
    /// プレミアム案内フルスクリーン（遷移元）
    case premiumPromoOpened(source: String)
    /// CSV 共有直前（種別）
    case csvExported(kind: String)
    /// 共有カードの共有アクション
    case shareCardShared(kind: String, source: String, screen: String, paywallState: String)
    /// 継続施策のインサイト表示
    case retentionInsightShown(kind: String, source: String)
}

/// 軽量イベントログ。DEBUG は `print`、全構成で `Logger`（本番は Console / TestFlight で確認可能）。
/// Firebase Analytics を追加する場合は `Analytics.logEvent` をここに追記し、下記の `event` 名を揃える。
enum AnalyticsEventService {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Kintore",
        category: "Analytics"
    )

    static func log(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(Self.debugLine(for: event))")
        #endif
        switch event {
        case .appLaunch(let isFirst):
            logger.notice("event=app_launch first_launch=\(String(isFirst), privacy: .public)")
        case .sessionCompleted(let sessionId):
            logger.notice("event=session_completed session_id=\(sessionId.uuidString, privacy: .private)")
        case .premiumPurchased:
            logger.notice("event=premium_purchased")
        case .onboardingCompleted:
            logger.notice("event=onboarding_completed")
        case .notificationPermissionGranted:
            logger.notice("event=notification_permission_granted")
        case .deepLinkOpened(let url):
            logger.notice("event=deep_link_opened url=\(url.absoluteString, privacy: .private)")
        case .statisticsScreenViewed:
            logger.notice("event=statistics_screen_viewed")
        case .premiumPromoOpened(let source):
            logger.notice("event=premium_promo_opened source=\(source, privacy: .public)")
        case .csvExported(let kind):
            logger.notice("event=csv_exported kind=\(kind, privacy: .public)")
        case .shareCardShared(let kind, let source, let screen, let paywallState):
            logger.notice("event=share_card_shared kind=\(kind, privacy: .public) source=\(source, privacy: .public) screen=\(screen, privacy: .public) paywall_state=\(paywallState, privacy: .public)")
        case .retentionInsightShown(let kind, let source):
            logger.notice("event=retention_insight_shown kind=\(kind, privacy: .public) source=\(source, privacy: .public)")
        }
    }

    private static func debugLine(for event: AnalyticsEvent) -> String {
        switch event {
        case .appLaunch(let first): return "app_launch(first:\(first))"
        case .sessionCompleted: return "session_completed"
        case .premiumPurchased: return "premium_purchased"
        case .onboardingCompleted: return "onboarding_completed"
        case .notificationPermissionGranted: return "notification_permission_granted"
        case .deepLinkOpened(let url): return "deep_link(url:\(url.absoluteString))"
        case .statisticsScreenViewed: return "statistics_screen_viewed"
        case .premiumPromoOpened(let source): return "premium_promo_opened(source:\(source))"
        case .csvExported(let kind): return "csv_exported(kind:\(kind))"
        case .shareCardShared(let kind, let source, let screen, let paywallState):
            return "share_card_shared(kind:\(kind),source:\(source),screen:\(screen),paywall:\(paywallState))"
        case .retentionInsightShown(let kind, let source):
            return "retention_insight_shown(kind:\(kind),source:\(source))"
        }
    }
}
