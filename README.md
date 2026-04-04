# Kintore（筋トレログ）

SwiftUI / SwiftData の iOS アプリ。Watch 拡張・Widget 同梱。

**リポジトリ**: [github.com/shunsukesaito00/kintore](https://github.com/shunsukesaito00/kintore)

## サポート

- [GitHub Issues](https://github.com/shunsukesaito00/kintore/issues)（テンプレート: `.github/ISSUE_TEMPLATE/`）
- 詳細: [`SUPPORT.md`](SUPPORT.md)

## 要件

- Xcode 16 以降（`project.yml` は Xcode 16.3 想定）
- iOS 17.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`project.yml` から `Kintore.xcodeproj` を生成する場合）

## ビルド

```bash
xcodegen generate   # プロジェクト再生成時
open Kintore.xcodeproj
```

シミュレータ向けビルド例は `scripts/build_sim.sh` を参照。

## ライセンス

未設定（`LICENSE` は任意）。
