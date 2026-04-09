# App Review 再提出チェックリスト（2.1(b) IAP / 新ビルド / 1.5 サポート URL）

## 推奨作業順（再提出前）

1. **GitHub:** **Settings → Pages** で **Build and deployment** の **Source** を **GitHub Actions** にし保存（初回のみ）→ **Actions** で **Deploy GitHub Pages** が成功するまで待つ（必要なら **Run workflow**）→ ブラウザで `https://shunsukesaito00.github.io/kintore-note/support/` が表示されることを確認  
2. **App Store Connect:** **Support URL** を上記のサポートページ URL に変更  
3. **App Store Connect:** IAP を審査提出し **アプリバージョンに関連付け** → **Xcode** で新ビルドをアップロード → **審査に再提出**

ワークフロー定義: [`.github/workflows/deploy-pages.yml`](../.github/workflows/deploy-pages.yml)。全体の提出手順: [AppStore_提出完全手順書_Kintore.md](./AppStore_提出完全手順書_Kintore.md)。

---

App Store Connect 上の作業が中心です。リポジトリのアプリコード変更は不要です（商品 ID は既に `com.shunsukesaito.kintore.premium`）。

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

## 審査メモ（コピー用）— アプリ内課金

```text
【アプリ内課金】非消耗型 com.shunsukesaito.kintore.premium を App Store Connect で審査提出済みです。App Review 用スクリーンショットを添付し、本バージョンに関連付けました。
```

```text
Non-Consumable IAP com.shunsukesaito.kintore.premium has been submitted for review with the required App Review screenshot and linked to this app version.
```

関連: [AppStore_提出完全手順書_Kintore.md](./AppStore_提出完全手順書_Kintore.md) §6

---

## Guideline 1.5 — サポート URL

このリポジトリでは **GitHub Pages のソースを GitHub Actions** にします（`docs/` をワークフローでデプロイ）。詳細は [support/README.md](./support/README.md)。

- [ ] **GitHub** → 対象リポジトリ → **Settings** → **Pages** → **Build and deployment** の **Source** で **GitHub Actions** を選び保存（初回のみ）
- [ ] **Actions** タブで **Deploy GitHub Pages** が緑（成功）である。失敗時はログを確認し、**Run workflow** で再実行可
- [ ] ブラウザで `https://shunsukesaito00.github.io/kintore-note/support/` が表示されることを確認
- [ ] **App Store Connect** → アプリ情報 / バージョンの **Support URL** を上記に変更（Issue 一覧のみの URL はガイドライン 1.5 で不十分とされることがある）
- [ ] 審査メモにサポート URL 更新を記載（任意・下記コピペ可）

**GitHub Actions を使わない場合:** ブランチから **`/docs` フォルダを公開**する手順は [support/README.md](./support/README.md) の「ブランチから直接公開する場合」を参照。**Actions とブランチ公開は併用しない**こと。

サポート用 HTML: [support/index.html](./support/index.html)

## 審査メモ（コピー用）— サポート URL

```text
Support URL now points to a dedicated support page with FAQ and instructions for contacting us (including GitHub Issues): https://shunsukesaito00.github.io/kintore-note/support/
```

```text
【サポート URL】FAQ・問い合わせ方法を記載したページに更新しました: https://shunsukesaito00.github.io/kintore-note/support/
```
