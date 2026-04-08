# Kintore Note（筋トレログ）

SwiftUI / SwiftData の iOS アプリ。Watch 拡張・Widget 同梱。

**リポジトリ**: [github.com/shunsukesaito00/kintore-note](https://github.com/shunsukesaito00/kintore-note)

（まだリポジトリ名が `kintore` のままなら、GitHub の **Settings → General → Repository name** で `kintore-note` に変更すると、上記 URL・App Store のサポート／プライバシー用リンクと一致します。リネーム後は旧 URL もしばらくリダイレクトされます。）

## サポート

- **App Store / ユーザー向け**: [サポートページ](https://shunsukesaito00.github.io/kintore-note/support/)（[公開手順](docs/support/README.md)）
- [GitHub Issues](https://github.com/shunsukesaito00/kintore-note/issues)（テンプレート: `.github/ISSUE_TEMPLATE/`）
- 詳細: [`SUPPORT.md`](SUPPORT.md)

## 要件

- Xcode 16 以降（`project.yml` は Xcode 16.3 想定）
- iOS 17.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`project.yml` から `Kintore.xcodeproj` を生成する場合）

## 署名（Development Team）

**`project.local.yml` に `DEVELOPMENT_TEAM: ""` のような空文字を書かないでください。** 空だと Xcode が必ず「Development team を選んで」と出ます。

次のどちらかです。

1. **`project.local.yml` に Team ID を書く（推奨）**  
   `project.local.yml.example` を参考に、`settings.base.DEVELOPMENT_TEAM` に Apple Developer の **Team ID（10桁）** を入れる → `xcodegen generate`（全ターゲットに反映）。

2. **Xcode の Signing で Team を選ぶだけにする**  
   `project.local.yml` は `settings.base: {}` のままにし、Xcode で各ターゲットの Team を選ぶ。**その後 `xcodegen generate` を実行すると、プロジェクトに Team が無い状態に戻る**ので、毎回 Xcode で選び直すか、やはり (1) で ID を固定するのが確実です。

## ビルド

```bash
xcodegen generate   # プロジェクト再生成時
open Kintore.xcodeproj
```

**Watch のアイコン**は iOS の `AppIcon.png` から `scripts/generate_watch_app_icons.py` で再生成できます（提出エラー時に実行）。

```bash
python3 scripts/generate_watch_app_icons.py && xcodegen generate
```

シミュレータ向けビルド例は `scripts/build_sim.sh` を参照。

## ライセンス

未設定（`LICENSE` は任意）。
