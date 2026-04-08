# サポートページ（GitHub Pages）

`index.html` は App Store Connect の **サポート URL**（ガイドライン 1.5）向けです。

## 公開 URL（リポジトリ名 `kintore-note`）

```
https://shunsukesaito00.github.io/kintore-note/support/
```

## GitHub で Pages を有効化（初回のみ）

このリポジトリでは **GitHub Actions** から `docs/` 全体をデプロイします（[`.github/workflows/deploy-pages.yml`](../../.github/workflows/deploy-pages.yml)）。

1. GitHub で対象リポジトリを開く  
2. **Settings** → **Pages**（左メニュー）  
3. **Build and deployment** の **Source** で **GitHub Actions** を選び、保存  
4. 既定ブランチ（例: `workout-set-adjust` や `main`）にワークフローを **push** するか、**Actions** タブで **Deploy GitHub Pages** を **Run workflow**（手動実行）  
5. ワークフローが緑になったら、数分後に上記 URL をブラウザで開いて確認  

`docs/.nojekyll` により Jekyll を無効化し、静的 HTML をそのまま配信します。

### ブランチから直接公開する場合（Actions を使わない）

**Settings** → **Pages** → Source: **Deploy from a branch** → Branch: `main` 等、Folder: **`/docs`**。  
（Actions と併用しないでください。どちらか一方に統一します。）
