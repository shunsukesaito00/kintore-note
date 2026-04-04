# Kintore — App Store 提出手順（参考）

**Bundle ID:** `com.kintore.app`  
審査基準・画面は変更される。[App Store レビューガイドライン](https://developer.apple.com/jp/app-store/review/guidelines/)、[App Store Connect ヘルプ](https://developer.apple.com/help/app-store-connect/) を参照。

---

## 関連 URL

| 用途 | URL |
|------|-----|
| App Store Connect | https://appstoreconnect.apple.com |
| Apple Developer（Identifiers 等） | https://developer.apple.com/account/resources/identifiers/list |
| レビューガイドライン | https://developer.apple.com/jp/app-store/review/guidelines/ |
| App Store Connect ヘルプ | https://developer.apple.com/help/app-store-connect/ |
| AdMob iOS プライバシー（参考） | https://developers.google.com/admob/ios/privacy |
| サポート（Issue 一覧） | https://github.com/shunsukesaito00/kintore/issues |

**App Store Connect 上で別途用意する HTTPS URL**

- **プライバシーポリシー**（必須）— 公開済みの独自 URL
- **マーケティング URL**（任意）
- **サポート URL** — 例: `https://github.com/shunsukesaito00/kintore/issues`

---

## 1. 固有情報

| 項目 | 内容 |
|------|------|
| 表示名 | Kintore |
| Bundle ID | com.kintore.app |
| 対応 OS | iOS 17.0 以降 |
| デバイス | iPhone |
| 同梱 | Kintore Watch、Kintore Widget |
| IAP（非消耗型） | `com.kintore.app.premium` |
| 広告 | Google Mobile Ads（Info.plist の GAD ID） |
| HealthKit | ワークアウト書き込み（設定で ON のとき） |
| iCloud | CloudKit、App Groups |
| URL スキーム | `kintore://` |
| 分析 | `AnalyticsEventService` は主に端末内 `os.Logger`。外部アナリティクス自動送信は未実装。プライバシー回答は実装・SDK に合わせる。 |

---

## 2. 事前条件

- Apple Developer Program 登録
- 開発用 Apple ID とチーム紐付け
- Mac / Xcode でアーカイブ可能
- プライバシーポリシーを HTTPS で公開
- 審査・サポート用の連絡先
- ストア用スクリーンショット（必須サイズ）

---

## 3. Identifiers / Capability

1. [Identifiers](https://developer.apple.com/account/resources/identifiers/list) で `com.kintore.app` を確認。
2. Xcode の Signing & Capabilities と一致: HealthKit、iCloud（CloudKit）、App Groups 等。

---

## 4. Xcode リリースビルド

1. Target「Kintore」→ Signing & Capabilities（Team、Bundle ID `com.kintore.app`）。
2. General: Version（例 1.0.0）、Build（提出ごとに増加）。
3. 実機または「Any iOS Device」で **Product → Archive**。
4. Organizer → **Distribute App** → App Store Connect → Upload。
5. ビルド反映まで数分〜数十分のことがある。

Watch / Widget は同一アーカイブに含まれる。

---

## 5. App Store Connect — 新規 App

[App Store Connect](https://appstoreconnect.apple.com) → マイ App → 新規 App。

| フィールド | 例 |
|------------|-----|
| プラットフォーム | iOS |
| 名前 | Kintore |
| 主要言語 | 日本語 |
| Bundle ID | com.kintore.app |
| SKU | kintore-ios-1（内部用一意） |

---

## 6. アプリ内課金

- 種類: 非消耗型
- 商品 ID: **`com.kintore.app.premium`**（コードと同一）
- 表示名・説明・価格・スクリーンショット（審査用）を登録し、バージョンと同じ審査に含める。

---

## 7. 価格・配信

本体価格、IAP、配信地域を設定。

---

## 8. App のプライバシー

申告内容は実装・ポリシー本文と一致させる。虚偽はリスクとなる。  
データ種別・第三者（AdMob 等）は [Google の開示資料](https://developers.google.com/admob/ios/privacy) 等と整合を取る。

---

## 9. アプリ情報（ストアメタデータ）

| 項目 | 例 |
|------|-----|
| サブタイトル（30 字以内） | セット管理と成長を、シンプルに |
| プライバシーポリシー URL | （公開済み HTTPS） |
| カテゴリ | プライマリ: ヘルスケア／フィットネス 等 |

### 説明文ドラフト

```text
Kintore（キントレ）は、筋トレ・ワークアウトの記録を続けやすくするためのiPhoneアプリです。セットごとの重量・回数などを入力し、セッションとして保存できます。

【主な機能】
・ワークアウト記録（セット入力・セッション保存）
・履歴の閲覧・カレンダーでの振り返り
・成長・統計の可視化（画面構成はアップデートで拡張される場合があります）
・種目・ルーティンの管理
・記録の共有（テキスト・画像など、機能はバージョンにより異なります）
・CSV エクスポート

【オプション】
・Apple ヘルスケアへのワークアウト保存（設定で有効化した場合）
・iCloud によるデータの同期（プレミアム機能・環境による）
・Apple Watch、ホーム画面ウィジェット（対応OS・端末による）

【プレミアム】
一部機能は買い切りの「プレミアム」で利用可能。詳細はアプリ内表示に従う。

【注意】
本アプリは医療機器ではない。健康上の判断は専門家に相談すること。
```

### キーワード（100 字以内・カンマ区切り）

```text
筋トレ,ワークアウト,トレーニング,記録,セット,重量,ベンチ,スクワット,フィットネス,筋力,ルーティン,ログ
```

### 著作権表記の例

```text
© 2026 （権利者名）
```

---

## 10. 審査メモ（コピー用）

```text
【ログイン】アカウント登録不要。

【アプリ内課金】非消耗型「プレミアム」（商品ID: com.kintore.app.premium）。サンドボックスで購入・復元可能。設定から購入画面へ遷移。

【ヘルスケア】設定のトグルで「ワークアウトをヘルスケアに保存」を任意有効化。OFF でも基本操作可。

【広告】Google AdMob。

【iCloud】プレミアム購入後、クラウド同期は iCloud・再起動が必要な場合あり。

【ディープリンク】kintore:// をウィジェット等から起動する場合あり。

【分析】主要イベントは端末内 os.Logger。外部アナリティクス SDK の送信はリリース構成による。
```

---

## 11. 輸出コンプライアンス・年齢レーティング

- 輸出: 質問票に沿って回答（標準 HTTPS 等のみの場合は免除が多い）。
- 年齢: 最新の質問票に回答。

---

## 12. プライバシーポリシーに含める項目（目安）

事業者名・連絡先、データの種類、目的、第三者提供、保存・削除、HealthKit / iCloud、改定日 等。

---

## 13. 提出・リリース

審査提出 → 承認後、手動または自動リリース。

---

## 14. チェックリスト

- Bundle ID / Version / Build
- 主要フロー・課金・復元の動作
- プライバシー回答とポリシー本文の一致
- スクリーンショットと実 UI の一致
- サポート URL の到達性
- IAP が審査バッチに含まれる状態

---

## 15. 改訂履歴

| 日付 | 内容 |
|------|------|
| 2026-04-04 | 初版 |
| 2026-04-04 | 表現整理・URL 一覧追加 |

本書は参考資料であり、法的助言ではない。規約・ガイドラインは Apple が更新する。
