# Xcode「Could not compute dependency graph / PIF transfer session」について

## これはソースコードのバグではありません

`MsgHandlingError(message: "unable to initiate PIF transfer session (operation in progress?)")` は、**Xcode のビルドシステム（PIF = Project Interchange Format）**が、別プロセスと競合したり内部状態が残ったときに出る **IDE／環境側のエラー**です。  
リポジトリの Swift コードや `project.pbxproj` の記述ミスが直接原因になることは稀です。

よくあるトリガー:

- **Xcode と別ツール**（ターミナルの `xcodebuild`、CI、Cursor の Swift 拡張など）が **同時に同じプロジェクト**を触っている  
- **`XCBBuildService`** が前回のビルドで固まったまま  
- **DerivedData** のロックやキャッシュ不整合  

## まず試すこと（上から順に）

1. **Xcode を完全終了**（⌘Q）し、**シミュレータ**も閉じる。  
2. 再度 Xcode でプロジェクトを開き、**Product → Clean Build Folder**（⇧⌘K）のあとビルド。  
3. まだ出る場合: **Activity Monitor** で `XCBBuildService` を終了するか、ターミナルで  
   `killall XCBBuildService`（Xcode は一度終了してから推奨）。  
4. それでもダメなら **DerivedData の削除**（Xcode 終了後）  
   - Xcode: **Settings → Locations → Derived Data** の矢印でフォルダを開き、`Kintore-` で始まるフォルダを削除  
   - またはターミナル: リポジトリ付属の `scripts/reset_xcode_build_services.sh` を参照  

## 同時実行を避ける

- Xcode でビルド／索引作成中に、**別ターミナルで同じ scheme の `xcodebuild`** を走らせない。  
- CI とローカル Xcode を同じ DerivedData でぶつけないよう、必要なら CI 用に別の `-derivedDataPath` を指定する。  

## それでも直らない場合

- macOS / Xcode を再起動  
- Xcode を最新の安定版に更新  
- 問題の **全文ログ**（Report navigator のビルドログ、`error:` 行）を控えて Apple Developer Forums / Stack Overflow を検索  

---

補助スクリプト: `scripts/reset_xcode_build_services.sh`（ビルドサービス停止＋任意で Kintore 用 DerivedData のみ削除）
