# App Review 再提出チェックリスト（2.1(b) IAP / 新ビルド）

App Store Connect 上の作業です。リポジトリのコード変更は不要です（商品 ID は既に `com.shunsukesaito.kintore.premium`）。

## Guideline 2.1(b) — アプリ内課金の審査提出

- [ ] **App Store Connect** → 対象アプリ → **収益化** または **機能** → **アプリ内課金**
- [ ] **非消耗型**の商品があり、**製品 ID** が次と**完全一致**する  
  `com.shunsukesaito.kintore.premium`
- [ ] 表示名・説明・価格・ローカライズを入力済み
- [ ] **App Review 用スクリーンショット**をアップロード（設定画面のプレミアム欄・購入ボタンが分かる画面）
- [ ] 当該 IAP の状態が **審査に提出**（Submit）済みで、メタデータに不足がない
- [ ] **App のバージョン**（提出中の iOS バージョン）の **アプリ内課金** セクションで、上記商品を **このバージョンに関連付け**

参考: [アプリ内課金を提出する](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/submit-an-in-app-purchase)

## 新ビルドの提出（Apple 要求の「新しいバイナリ」）

- [ ] Xcode で **Release** アーカイブを作成
- [ ] **App Store Connect** → **TestFlight / App** にビルドをアップロード
- [ ] 審査対象バージョンに **新ビルドを選択**
- [ ] IAP が紐づいた状態で **審査に再提出**

## 審査メモに書くとよい一文（コピー用）

```text
【アプリ内課金】非消耗型 com.shunsukesaito.kintore.premium を App Store Connect で審査提出済みです。App Review 用スクリーンショットを添付し、本バージョンに関連付けました。
```

関連: [AppStore_提出完全手順書_Kintore.md](./AppStore_提出完全手順書_Kintore.md) §6

---

## Guideline 1.5 — サポート URL

- [ ] リポジトリで **GitHub Pages** を有効化（**Settings → Pages** → ソース: **`/docs`**）。手順: [support/README.md](./support/README.md)
- [ ] ブラウザで `https://shunsukesaito00.github.io/kintore-note/support/` が表示されることを確認
- [ ] **App Store Connect** → アプリ情報 / バージョンの **Support URL** を上記に変更（Issue 一覧の URL のみは不可のため）
- [ ] 審査メモに「サポート URL をユーザー向けページに更新」と一言添える（任意）

サポート用 HTML: [support/index.html](./support/index.html)
