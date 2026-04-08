// File: Core/Services/PremiumService.swift
// StoreKit 2 買い切りプレミアム。キャッシュを UserDefaults に保持し起動時のコンテナ判定に使用。

import Foundation
import StoreKit

private let premiumProductId = "com.shunsukesaito.kintore.premium"
private let isPremiumUserDefaultsKey = "kintore.isPremium"
/// プレミアム昇格後、SwiftData の iCloud ストアを使うには再起動が必要。`true` のとき案内アラートを出す。
private let needsRestartForCloudSyncKey = "kintore.needsRestartForCloudSync"

@MainActor
@Observable
final class PremiumService {
    enum Feature: String, CaseIterable {
        case basicLogging
        case historyView
        case advancedAnalytics
        case periodComparison
        case shareCards
        case japanGymDatabase
    }

    static let shared = PremiumService()

    /// プレミアム所持（UI 用。キャッシュ + Transaction で更新）
    private(set) var isPremium: Bool = false
    /// 購入可能な商品（未取得なら nil）
    private(set) var product: Product?
    /// 購入処理中
    private(set) var isPurchasing = false
    /// エラーメッセージ（表示用）
    private(set) var errorMessage: String?

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: isPremiumUserDefaultsKey)
    }

    /// 起動時・復元時に呼ぶ。Transaction.currentEntitlements でキャッシュを更新。
    func refresh() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result, tx.productID == premiumProductId else { continue }
            hasPremium = true
            break
        }
        await MainActor.run {
            isPremium = hasPremium
            UserDefaults.standard.set(hasPremium, forKey: isPremiumUserDefaultsKey)
        }
    }

    /// 商品一覧を取得（設定画面表示前に呼ぶ）
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [premiumProductId])
            await MainActor.run {
                product = products.first
            }
        } catch {
            await MainActor.run {
                errorMessage = "商品の取得に失敗しました"
            }
        }
    }

    /// 購入実行
    func purchase() async {
        guard let product = product else {
            await MainActor.run { errorMessage = "商品を読み込み中です" }
            return
        }
        await MainActor.run { isPurchasing = true; errorMessage = nil }
        defer { Task { @MainActor in PremiumService.shared.isPurchasing = false } }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await tx.finish()
                    let wasPremium = await MainActor.run { self.isPremium }
                    await refresh()
                    await MainActor.run {
                        if self.isPremium && !wasPremium {
                            UserDefaults.standard.set(true, forKey: needsRestartForCloudSyncKey)
                        }
                    }
                    AnalyticsEventService.log(.premiumPurchased)
                case .unverified:
                    await MainActor.run { errorMessage = "購入の検証に失敗しました" }
                }
            case .userCancelled:
                break
            case .pending:
                await MainActor.run { errorMessage = "購入は保留中です（ファミリー承認など）" }
            @unknown default:
                break
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    /// 復元
    func restore() async {
        let wasPremium = await MainActor.run { self.isPremium }
        await MainActor.run { errorMessage = nil }
        await refresh()
        await MainActor.run {
            if self.isPremium && !wasPremium {
                UserDefaults.standard.set(true, forKey: needsRestartForCloudSyncKey)
            }
        }
    }

    /// iCloud 同期ストアへの切り替え案内をまだ出すべきか（購入直後に `true`）。
    static var isCloudSyncRestartPending: Bool {
        UserDefaults.standard.bool(forKey: needsRestartForCloudSyncKey)
    }

    /// 再起動案内アラートを閉じたときに呼ぶ。
    static func acknowledgeCloudSyncRestartPrompt() {
        UserDefaults.standard.set(false, forKey: needsRestartForCloudSyncKey)
    }

    /// 起動時にキャッシュを読む用（同期的にコンテナ判定に使う）
    nonisolated static var cachedIsPremium: Bool {
        UserDefaults.standard.bool(forKey: isPremiumUserDefaultsKey)
    }

    /// プレミアムの実利は **広告非表示のみ**。その他の機能は無料で利用可能（`hasAccess` は常に `true`）。

    func hasAccess(to feature: Feature) -> Bool {
        true
    }
}
