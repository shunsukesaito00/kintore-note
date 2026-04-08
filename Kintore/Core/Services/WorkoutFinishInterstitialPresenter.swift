// File: Core/Services/WorkoutFinishInterstitialPresenter.swift
// トレーニング保存確定の直前にインタースティシャルを表示（プレミアムはスキップ）。
// 1 セッションあたり「筋トレを締める」タイミングのみ出すため、呼び出し側で `shouldPresentInterstitial` を制御する。

import Foundation
import GoogleMobileAds
import UIKit

/// 広告 SDK のオブジェクトをメインスレッドのみで扱う前提で、ロード完了ハンドラから MainActor へ渡すための合意。
extension InterstitialAd: @unchecked Sendable {}

@MainActor
final class WorkoutFinishInterstitialPresenter: NSObject, FullScreenContentDelegate {
    static let shared = WorkoutFinishInterstitialPresenter()

    private var pendingCompletion: (() -> Void)?
    private var retainedAd: InterstitialAd?

    private override init() {
        super.init()
    }

    /// - Parameters:
    ///   - shouldPresentInterstitial: `false` のとき広告は出さず即 `completion`（例: フォーカス画面で最後の種目以外から早期終了したとき）。
    ///   - completion: 保存処理。プレミアムは即実行。広告ありの場合は閉じたあと（読込失敗・表示失敗時はその場）で実行。
    func runAfterInterstitialIfNeeded(shouldPresentInterstitial: Bool = true, completion: @escaping () -> Void) {
        guard shouldPresentInterstitial else {
            completion()
            return
        }
        guard !PremiumService.shared.isPremium else {
            completion()
            return
        }
        pendingCompletion = completion
        let unitID = AdMobConfiguration.interstitialWorkoutFinishAdUnitID
        InterstitialAd.load(with: unitID, request: Request()) { [weak self] ad, _ in
            Task { @MainActor in
                guard let self else {
                    completion()
                    return
                }
                guard let ad else {
                    self.clearPendingAndRunSave()
                    return
                }
                self.retainedAd = ad
                ad.fullScreenContentDelegate = self
                ad.present(from: UIApplication.kintore_topViewController())
            }
        }
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        clearPendingAndRunSave()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        clearPendingAndRunSave()
    }

    private func clearPendingAndRunSave() {
        let block = pendingCompletion
        pendingCompletion = nil
        retainedAd = nil
        block?()
    }
}
