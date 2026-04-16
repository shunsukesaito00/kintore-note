// File: Core/Services/AdMobConfiguration.swift
// AdMob のユニット ID。DEBUG では公式テスト ID を使い、誤クリックや計測異常を避ける。
//
// app-ads.txt（販売者開示）: ストアに載せたサイトのルートに公開する（本リポジトリは GitHub Pages で
// `docs/` がサイトルートのためマスターは docs/app-ads.txt → 例: …/kintore-note/app-ads.txt）。

import Foundation

enum AdMobConfiguration {
    /// ネイティブアドバンス（ホーム末尾など）
    static var nativeHomeAdUnitID: String {
        #if DEBUG
        "ca-app-pub-3940256099942544/3986624511"
        #else
        "ca-app-pub-3293510133025826/3993295523"
        #endif
    }

    /// インタースティシャル（トレーニング終了・保存確定時）
    static var interstitialWorkoutFinishAdUnitID: String {
        #if DEBUG
        "ca-app-pub-3940256099942544/4411468910"
        #else
        "ca-app-pub-3293510133025826/6823472993"
        #endif
    }
}
