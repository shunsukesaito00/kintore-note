# RepLog ウィジェット拡張

## Xcode での追加手順

1. **Widget Extension ターゲットを追加**
   - File → New → Target → iOS → Widget Extension
   - Product Name: `KintoreWidget`
   - Include Configuration App Intent: オフでOK
   - Finish

2. **App Group を有効化**
   - メインアプリ（Kintore）の Signing & Capabilities で **App Groups** を追加
   - 識別子: `group.com.kintore.app`
   - KintoreWidget ターゲットにも同じ App Groups を追加

3. **既存ファイルに差し替え**
   - Xcode が自動作成した Widget の Swift ファイルを削除
   - このフォルダの `RepLogWidget.swift` と `RepLogWidgetBundle.swift` をプロジェクトに追加し、KintoreWidget ターゲットにのみ所属させる

4. **メインアプリからデータを渡す**
   - メインアプリで `WidgetDataStore.updateFrom(modelContext:)` が呼ばれると、App Group の UserDefaults に今週の回数・連続実施週数・直近PRが書き出され、タイムラインが再読み込みされます
   - ホーム画面にウィジェットを追加すると「今週○回」「PR: 種目名 100kg×5」が表示されます

5. **ウィジェットタップでアプリを開く**
   - メインアプリ（Kintore）に URL スキーム `kintore` が登録されている必要があります（リポジトリの `Kintore/Info.plist` と同内容を Xcode の Info に反映するか、ファイルをターゲットに含める）。
   - `RepLogWidgetView` には `.widgetURL(URL(string: "kintore://home")!)` が付いており、タップでアプリが開きホームタブが表示されます。
