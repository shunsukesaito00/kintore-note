# Kintore（筋トレログ）

SwiftUI / SwiftData の iOS アプリ。Watch 拡張・Widget 同梱。

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

未設定（必要に応じて `LICENSE` を追加してください）。
