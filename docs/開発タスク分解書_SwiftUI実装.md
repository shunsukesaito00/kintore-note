# 筋トレログアプリ SwiftUI 実装タスク分解書

**版**: 1.0  
**前提**: 要件定義書 1.0、Swift / SwiftUI / SwiftData / MVVM、個人開発

---

## 実装前に固定すべき仕様（必読）

実装着手前に、以下5項目を仕様として確定すること。判断が曖昧なまま進めると後戻りコストが大きい。

---

### 1. PR（パーソナルレコード）判定ルール

| 項目 | 固定案 | 理由 |
|---|---|---|
| **採用ルール** | **「同一種目における 1セットあたりの volume（weight × reps）の最大値」をPRとする** | 実装がシンプルで、ユーザーに説明しやすい。「重量だけ」「回数だけ」の複合ルールより、volume 1指標で統一する。 |
| **比較単位** | 1セット単位。複数セットの合計はPRにしない | 前回表示と整合し、記録画面の「ベスト 42.5kg x 8」表示と一致する。 |
| **更新タイミング** | セットを「完了」した時点で、その種目の既存PR（volume）と比較し、上回れば PersonalRecord を 1件 insert（または update） | セッション終了時の一括計算より、記録の直後にPRが変わる方がフィードバックが早い。 |
| **表示** | 記録画面では「ベスト 42.5kg × 8 (3/1)」形式。重量・回数・達成日を表示 | 要件定義どおり。 |
| **未達の扱い** | 重量のみ・回数のみの記録（片方 nil）は volume 計算から除外。0 扱いにはしない | 意図しないPR更新を防ぐ。 |

**初版で採用しないもの**: 1RM推定、複合ルール（「最大重量」「最大回数」を別PRとする）は将来拡張とする。

---

### 2. 前回記録の定義

| 項目 | 固定案 | 理由 |
|---|---|---|
| **「前回」の定義** | **同一 exerciseId について、endedAt が存在する（完了した）WorkoutSession に紐づく WorkoutExercise のうち、セッションの endedAt が最も新しい 1件**。その WorkoutExercise に紐づく WorkoutSet を「前回のセット」として使用 | 種目単位で直近実績を取る。ルーティンに依存しないため、ルーティン変更後も正しく前回が取れる。 |
| **表示内容** | 前回の「重量×回数×セット数」、および「最終実施日」（例: 最終 3/6） | 記録画面で「前回 40kg x 10 x 3 最終 3/6」のように表示。 |
| **ルーティンとの関係** | 「前回のルーティンで続ける」は、**直近で開始に使った WorkoutTemplate を取得し、そのテンプレの種目順でセッションを開始する**意味とする。前回「記録」の種目順は、そのセッションの WorkoutExercise の order で決まる。テンプレとセッションの種目順は一致させるが、前回「値」の取得はあくまで種目（exerciseId）単位 | 前回ルーティン＝テンプレの再利用。前回値＝種目ごとの直近実績。役割を分離する。 |
| **セット数のデフォルト** | 新規種目追加時、前回のセット数が N なら、記録画面では N 個の空セットを初期表示する（重量・回数は未入力）。ユーザーが「前回と同じ」で一括コピーしやすい | 入力速度のため。 |

---

### 3. メモタグの保持方式

| 項目 | 固定案 | 理由 |
|---|---|---|
| **保持方式** | **WorkoutExercise には memoTagIds を [String] で保持する。値は MemoTag マスタの id（初版は固定文字列、例: "form_bad", "pain"）と一致させる** | SwiftData で [UUID] のリレーションは扱いが重い。String の配列ならスキーマが単純で、マスタは別テーブル（MemoTag）で固定リストを保持。将来「ユーザー定義タグ」を足す場合も id を文字列のまま拡張できる。 |
| **MemoTag マスタ** | 初版はアプリ内に固定リストで持つ（SwiftData の MemoTag に初回投入するか、または enum + 静的配列でコード上で定義）。id: String, label: String, sortOrder: Int | 表示ラベルと並び順を一元管理。 |
| **WorkoutExercise のスキーマ** | memoTagIds: [String], freeMemo: String? | 永続化は SwiftData の Transformable または [String] の保存可能な形で。SwiftData で配列がそのまま使えない場合は、カンマ区切り1文字列で保存し、読み込み時に [String] にパースする。 |

**推奨**: SwiftData の @Model で `var memoTagIds: [String]` がサポートされているか確認する。されていなければ `var memoTagIdsString: String`（例: "form_bad,pain"）とし、Service 層で [String] に変換して扱う。

---

### 4. 重量単位の扱い

| 項目 | 固定案 | 理由 |
|---|---|---|
| **初版** | **kg 固定とする。UserPreference の weightUnit は初版では持たず、表示はすべて「kg」** | MVP で入力・表示・PR・総挙上の一貫性を保ち、単位変換バグを防ぐ。日本では kg が主である。 |
| **将来** | 設定に「単位: kg / lb」を追加し、表示時のみ変換する（保存は kg で統一するか、ユーザー選択単位で保存するかは将来設計）。初版では実装しない | リリース優先。 |

---

### 5. 休憩タイマー挙動

| 項目 | 固定案 | 理由 |
|---|---|---|
| **開始** | **セット完了（記録）時に自動で休憩タイマーを開始する。手動で「休憩開始」ボタンも用意する** | ジムでの流れに沿う。自動開始をデフォルトにしつつ、記録前に休憩を取りたい場合に手動開始も使える。 |
| **デフォルト秒数** | 種目（Exercise）の defaultRestSeconds があればそれを使い、なければ UserPreference の defaultRestSeconds（初版は 90 秒固定でよい） | 種目別・全体のデフォルトを分離。 |
| **バックグラウンド** | **目標終了時刻（Date）を UserDefaults またはメモリに保持し、アプリ復帰時に「現在時刻 vs 目標時刻」で残り時間を再計算する。残りが 0 以下なら「終了済み」とみなす。休憩終了時はローカル通知を 1 回送る（通知許可は初回のみ求める）** | バックグラウンドで Timer を動かし続けない。復帰時に差分計算で補正する方式が破綻しにくい。 |
| **フォアグラウンド** | Timer.publish または DispatchQueue.main.asyncAfter で 1 秒ごとに UI 更新。残り秒数を表示し、0 で止める | シンプルに実装。 |
| **スキップ・延長** | 「スキップ」で即終了。「延長」で +30 秒等、仕様を 1 つ決める | 初版は延長は「+30秒」固定でよい。 |

---

## 1. 実装全体方針

### 1.1 MVP 実装の基本戦略

- **「記録できる → 前回が見える → ルーティンで速く始められる → 履歴・統計で振り返れる」** の順で価値を積み上げる。
- データモデルと永続化を先に固め、その上に画面を乗せる。モデル変更の後戻りを避ける。
- 各フェーズの終了時点で「動くもの」が残るようにする（例: Phase 1 終了時点で「種目を選んでセットを記録し、保存・前回表示までできる」）。

### 1.2 先に作るべきもの

- SwiftData モデル（Exercise, WorkoutSession, WorkoutExercise, WorkoutSet, WorkoutTemplate, WorkoutTemplateItem, MemoTag, PersonalRecord, UserPreference）。
- 種目マスタの CRUD とプリセット投入（初回起動時）。
- ワークアウト記録の最小ループ（1 セッション・1 種目・複数セットの保存、前回取得・表示）。
- 前回記録取得サービス（exerciseId ベース）。
- PR 判定・更新サービス（volume ベース、セット完了時）。

### 1.3 後回しにすべきもの

- 進歩提案ロジック（重量アップ/維持の提案）。記録・履歴が固まってからでよい。
- 種目別休憩の詳細設定（初版は全体デフォルト 90 秒＋種目 defaultRestSeconds のみ）。
- 単位切替（kg/lb）、テーマ切替（初版はシステムに追随でよい場合あり）。
- カレンダーの月切替アニメーション、グラフの凝った表現。

### 1.4 スコープ管理上の注意点

- 「初版で絶対に入れる」: 記録・前回表示・前回コピー・ルーティン適用・休憩タイマー・履歴一覧・基本統計（回数・総挙上・PR）・構造化メモタグ・ホームの記録入口。
- 「初版で削ってもよい」: 進歩提案の自動表示、今週サマリ、部位別頻度グラフ、種目詳細の期間切替、設定の詳細項目。削る場合は「初版で削ってよいもの」の章に従う。

### 1.5 技術的に難しい箇所の先読み

- **休憩タイマー**: バックグラウンド復帰時の残り時間再計算と、ローカル通知の 1 本化。目標時刻をどこに持つか（ViewModel のみだとアプリ終了で消えるため、UserDefaults または軽い永続化を検討）。
- **SwiftData のリレーション**: 逆参照（WorkoutSession → WorkoutExercise）の取得、削除時のカスケード。公式ドキュメントに沿ってリレーションを定義する。
- **前回ルーティンで続ける**: 直近セッションの workoutTemplateId からテンプレを取得し、テンプレの種目順で WorkoutExercise を並べる。テンプレが削除されている場合は「新規で開始」にフォールバックする仕様を決める。

---

## 2. 実装フェーズ分解

| フェーズ | 目的 | 完了条件 | 実装対象 | 先にやる理由 |
|---|---|---|---|---|
| **Phase 0** | プロジェクトとアプリ骨格の作成 | 起動して Tab とプレースホルダ画面が表示される | プロジェクト作成、TabView、SwiftData スキーマ登録、ディレクトリ・プレースホルダ View | 以降のタスクがすべてこの上に乗るため |
| **Phase 1** | データモデルと種目・記録の最小ループ | 種目を選び、セットを記録して保存でき、前回値が記録画面に表示される | 全モデル、種目 CRUD、プリセット投入、記録画面（1 種目・複数セット）、前回取得、PR 更新 | 差別化の核「前回表示」がここで成立する |
| **Phase 2** | ルーティンとクイック記録・休憩 | ルーティンで開始・前回コピー・+rep/+kg・休憩タイマーが動く | ルーティン CRUD、開始画面、前回ルーティン再開、クイックボタン、休憩タイマー、メモタグ | 記録速度と継続の体験を完成させる |
| **Phase 3** | 履歴と統計 | 日付別履歴・カレンダー・セッション詳細・基本統計が使える | 履歴一覧、カレンダー、セッション詳細、統計（回数・総挙上・PR・部位）、種目詳細/推移 | 成長実感と振り返りを提供する |
| **Phase 4** | ホーム・設定・仕上げ | ホームから 2 タップで記録開始、設定で休憩デフォルト等を変更できる | ホーム、設定、進歩提案（簡易）、デザイン統一、アクセシビリティ最低限 | リリース可能な完成度にする |

---

## 3. タスク一覧（最重要）

### Phase 0: プロジェクト基盤構築

| タスクID | タスク名 | 概要 | 実装内容 | 依存 | 優先度 | 完了条件 | 備考 |
|---|---|---|---|---|---|---|---|
| T0-1 | 新規 Xcode プロジェクト作成 | SwiftUI App テンプレートで作成 | プロジェクト作成、iOS 17+、SwiftUI App Lifecycle、SwiftData 有効化 | なし | P0 | ビルド成功・シミュレータ起動 |  |
| T0-2 | SwiftData ModelContainer の登録 | アプリ起動時にモデルを登録 | KintoreApp で modelContainer を .modelContainer(for: [...]) で指定（Phase 1 でモデル追加後に実体を入れる） | T0-1 | P0 | 起動時にクラッシュしない | モデル未作成時は空配列でよい |
| T0-3 | TabView ベースのルート構造作成 | 4 Tab（ホーム・履歴・統計・設定） | ContentView で TabView、各 Tab にプレースホルダ View（Text のみ） | T0-1 | P0 | 4 Tab が切り替え可能 |  |
| T0-4 | ディレクトリとプレースホルダファイル作成 | 推奨ディレクトリに空ファイルを配置 | App/, Modules/Home, Workout, Routine, History, Statistics, Exercise, Settings, Core/Models, Repositories, Services, Utilities, Resources | T0-1 | P1 | ナビゲーションで各フォルダが存在 | 後続タスクで実装するファイルの置き場を決める |
| T0-5 | 共通カラー・フォントの定義（スタブ） | デザイン仕様の色・フォントを 1 か所で定義 | Core/Utilities/AppTheme.swift 等で Color / Font の extension、アクセント色・背景色の定数 | T0-1 | P2 | 他画面から参照できる | Phase 4 で中身を充実させる |

---

### Phase 1: データモデルと永続化・記録の最小ループ

| タスクID | タスク名 | 概要 | 実装内容 | 依存 | 優先度 | 完了条件 | 備考 |
|---|---|---|---|---|---|---|---|
| T1-1 | Exercise SwiftData モデル定義 | 種目エンティティ | @Model class Exercise: id, name, bodyPartTag, equipmentTag, defaultRestSeconds, isPreset, isFavorite, sortOrder, createdAt | T0-2 | P0 | ビルド成功、マイグレーションなしで保存可能 |  |
| T1-2 | WorkoutSession / WorkoutExercise / WorkoutSet モデル定義 | セッション・種目・セット | @Model で 3 クラス、リレーション（Session 1:N Exercise, Exercise 1:N Set）、endedAt, durationSeconds, weight, reps, completedAt 等 | T1-1 | P0 | セッションを保存すると Exercise/Set が連動して保存される | 削除は手動で子から行うか、cascade を要確認 |
| T1-3 | WorkoutTemplate / WorkoutTemplateItem モデル定義 | ルーティン | @Model、Template 1:N TemplateItem、TemplateItem が exerciseId（UUID または Exercise 参照）と order を持つ | T1-1 | P0 | テンプレ保存・種目並びが再現できる | Phase 2 で利用 |
| T1-4 | MemoTag / PersonalRecord / UserPreference モデル定義 | メモタグ・PR・設定 | MemoTag: id, label, sortOrder。PersonalRecord: exerciseId, weight, reps, achievedAt, volume。UserPreference: シングルトン想定で defaultRestSeconds 等 | T1-1 | P0 | 保存・読み取りができる | memoTagIds は WorkoutExercise に [String] または 1 文字列で持つ |
| T1-5 | ModelContainer に全モデルを登録 | アプリで SwiftData が使えるようにする | .modelContainer(for: [Exercise.self, WorkoutSession.self, ...]) | T1-1〜T1-4 | P0 | 起動し、モデルが認識される |  |
| T1-6 | ExerciseRepository 実装（CRUD） | 種目の永続化 | fetchAll, fetchById, add, update, delete, search(name), fetchFavorites。ModelContext を注入 | T1-5 | P0 | 種目の追加・更新・削除・検索ができる |  |
| T1-7 | プリセット種目データの定義と投入 | 初回利用時に種目が存在するようにする | 固定リスト（名前・部位・器具・rest）をコードまたは JSON で定義。初回起動判定（UserDefaults 等）で Exercise を一括 insert | T1-6 | P0 | 初回起動後に種目一覧が表示される | isPreset = true |
| T1-8 | WorkoutSessionRepository 実装 | セッションの保存・取得 | save(session), fetchRecent(limit), fetchByDateRange, fetchById。WorkoutExercise / WorkoutSet は Session に紐づけて保存 | T1-2, T1-5 | P0 | セッションを保存し、一覧で取得できる |  |
| T1-9 | LastRecordService 実装（前回記録取得） | 種目ごとの前回 WorkoutExercise + Sets を返す | exerciseId を渡し、endedAt が非 nil の Session に紐づく WorkoutExercise のうち、セッションが最も新しい 1 件を取得。その Sets を返す | T1-8 | P0 | 前回の重量・回数・セット数が取得できる | 固定仕様「前回の定義」に従う |
| T1-10 | PersonalRecordService 実装（PR 判定・更新） | セット完了時に volume を比較し PR を更新 | セットの weight, reps から volume を計算。その種目の既存 PR と比較し、上回れば PersonalRecord を 1 件 insert（または update） | T1-4, T1-8 | P0 | 記録後に PR が更新される | 固定仕様「PR 判定」に従う |
| T1-11 | 種目ピッカー View 実装 | 記録時に種目を選ぶ画面 | リスト表示、検索欄、お気に入りフィルタ（任意）。タップで選択して閉じる。ExerciseRepository を ViewModel 経由で利用 | T1-6, T0-3 | P0 | 種目を選んで戻れる | シートまたはプッシュ |
| T1-12 | WorkoutRecordView 最小版実装 | 1 種目・複数セットの記録 | 種目名、セットリスト（重量・回数・完了）、セット追加、「記録」でセット完了。開始時刻はセッション作成時、終了は「終了」ボタンで | T1-8, T1-11 | P0 | セットを入力して保存できる | 前回表示は T1-13 で |
| T1-13 | 記録画面に前回値・PR 表示を組み込む | 前回とベストを表示 | LastRecordService で前回取得、PersonalRecordService（または Repository）で PR 取得。記録画面の ViewModel で保持し、View に表示 | T1-9, T1-10, T1-12 | P0 | 記録画面に「前回 40kg x 10 x 3」「ベスト 42.5kg x 8」が表示される |  |
| T1-14 | セット完了時に PR 更新を呼び出す | 記録と PR の連動 | セットを「完了」したタイミングで PersonalRecordService.updateIfNeeded を呼ぶ | T1-10, T1-12 | P0 | ベストを更新すると表示が変わる |  |
| T1-15 | 今日のワークアウト開始プレースホルダから記録画面へ遷移 | 開始 → 記録の導線 | 「新規で開始」で種目未選択の状態で WorkoutRecordView を開く。種目選択は記録画面内で行う | T1-12, T0-3 | P0 | ホーム→開始→記録までつながる | ルーティンは Phase 2 |

---

### Phase 2: ルーティン・クイック記録・休憩・メモタグ

| タスクID | タスク名 | 概要 | 実装内容 | 依存 | 優先度 | 完了条件 | 備考 |
|---|---|---|---|---|---|---|---|
| T2-1 | WorkoutTemplateRepository 実装 | ルーティン CRUD | save, fetchAll, fetchById, delete。TemplateItem は Template に紐づけて保存。lastUsedAt の更新 | T1-3, T1-5 | P0 | ルーティンの作成・一覧・削除ができる |  |
| T2-2 | ルーティン一覧 View 実装 | テンプレの一覧・選択 | カードまたはリスト、種目数・最終実施日表示。タップで「このルーティンで開始」に繋げる。新規作成ボタン | T2-1 | P0 | ルーティン一覧が表示され、選択できる |  |
| T2-3 | ルーティン編集 View 実装 | 種目並び替え・追加・削除 | 種目リスト、ドラッグで並び替え、種目追加（ピッカー）、削除、名前入力、保存 | T2-1, T1-11 | P0 | ルーティンを編集して保存できる |  |
| T2-4 | 開始画面でルーティン選択・「前回のルーティンで続ける」 | 開始フローの完成 | ルーティン一覧を表示。「前回のルーティンで続ける」は直近セッションの templateId からテンプレを取得し、その種目順で開始 | T2-1, T2-2, T1-8 | P0 | 2 タップで記録開始できる | テンプレ削除時はフォールバック |
| T2-5 | 記録画面で複数種目をルーティン順に表示・切替 | 同一画面で種目を切り替え | 現在の種目インデックス、種目リスト（テンプレ or 手動追加）、「次へ」「前へ」またはセグメント。1 種目ずつ表示 | T1-12, T2-4 | P0 | ルーティンで開始した場合、種目が順に表示される |  |
| T2-6 | 「前回と同じ」ボタン実装 | 現在セットに前回の重量・回数をコピー | ViewModel で前回の 1 セット目（または N セット目）の値を現在編集中セットにセット | T1-13 | P0 | 1 タップで前回値が入力される |  |
| T2-7 | 「+1rep」「+2.5kg」「-2.5kg」ボタン実装 | 前回から一定量増減 | 前回値に対して +1 rep、+2.5 kg、-2.5 kg を適用して現在セットに反映 | T1-13 | P0 | クイックで増減できる | 単位は kg 固定 |
| T2-8 | 種目追加時の前回セット数で空セットを初期表示 | セット数のデフォルト | 前回が 3 セットなら、その種目で 3 つの空セットを表示。ユーザーは「前回と同じ」で一括 or 個別入力 | T1-9, T1-12 | P0 | 新規種目追加時にも前回セット数が効く |  |
| T2-9 | 休憩タイマー用の目標時刻保持と復帰時再計算 | バックグラウンド対応 | 休憩開始時に目標終了 Date を計算して保持（UserDefaults または ViewModel で保持）。アプリ復帰時に現在時刻と比較し残りを再計算 | なし | P0 | バックグラウンドから復帰しても残り時間が正しい | 固定仕様「休憩タイマー」に従う |
| T2-10 | 休憩タイマー UI とセット完了時の自動開始 | 表示と自動開始 | 残り秒数表示、スキップ・延長ボタン。セット完了時に自動でタイマー開始。種目 defaultRestSeconds または UserPreference | T2-9, T1-12 | P0 | セット完了で休憩が始まり、スキップで終了できる |  |
| T2-11 | 休憩終了のローカル通知 | 通知 1 本 | 休憩開始時に UNUserNotificationCenter でローカル通知をスケジュール（終了時刻に 1 回） | T2-9 | P0 | アプリがバックグラウンドでも休憩終了時に通知 | 許可は初回に求める |
| T2-12 | MemoTag 固定リストと WorkoutExercise への保存 | 構造化メモ | MemoTag を固定リストで定義。記録画面で種目ごとにタグを複数選択。WorkoutExercise の memoTagIds（または 1 文字列）に保存 | T1-4, T1-12 | P0 | メモタグを選んで記録に紐づけられる | 固定仕様「メモタグ」に従う |
| T2-13 | UserPreference の読み書き（休憩デフォルト） | 設定の永続化 | defaultRestSeconds の取得・更新。Repository または単一の Service でシングルトン的に扱う | T1-4 | P1 | 設定で休憩デフォルトを変更できる | 設定画面は Phase 4 |

---

### Phase 3: 履歴・統計

| タスクID | タスク名 | 概要 | 実装内容 | 依存 | 優先度 | 完了条件 | 備考 |
|---|---|---|---|---|---|---|---|
| T3-1 | 履歴一覧 View 実装 | 日付別セッション一覧 | SessionRepository で日付降順に取得。日付・ルーティン名・種目数・所要時間・総挙上（任意）を表示。タップでセッション詳細へ | T1-8 | P0 | 過去のセッションが一覧で見える |  |
| T3-2 | セッション詳細 View 実装 | 1 回分の種目・セット・メモ | セッションに紐づく WorkoutExercise を order で表示。各種目のセット一覧、メモタグ・自由文 | T1-8, T3-1 | P0 | 日付をタップすると中身が見える |  |
| T3-3 | 総挙上重量計算サービス | セッション・期間の総挙上 | 1 セット: weight*reps、未入力は 0。セッション・期間で合計。Service に集約 | T1-2 | P0 | セッション詳細や統計で総挙上を表示できる |  |
| T3-4 | カレンダー View 実装 | 月表示・実施日マーク | 月グリッド、実施日にはドットまたはマーク。タップでその日の履歴へ。月切替 | T1-8 | P0 | カレンダーで実施日が分かる | 初版は月のみでよい |
| T3-5 | 統計 View の骨子実装 | 回数・総挙上・PR・部位 | ワークアウト回数（今週/今月/全期間）、総挙上重量、PR 更新履歴リスト、部位別実施回数（集計ロジック） | T1-8, T1-10, T3-3 | P0 | 統計画面で数値が表示される |  |
| T3-6 | 種目別履歴・推移の取得と表示 | 種目詳細画面 | 種目を指定し、その種目の過去セッション内の WorkoutExercise を時系列で取得。推移グラフ（簡易）またはリスト | T1-8, T1-9 | P0 | 種目を選ぶと履歴・推移が見える | 期間切替は初版は「全期間」のみでも可 |
| T3-7 | 部位別頻度集計 | 統計用 | Exercise の bodyPartTag でグルーピングし、セッション数または種目実施回数を集計。Service に実装 | T1-1, T1-8 | P1 | 部位別の実施回数が分かる |  |

---

### Phase 4: 仕上げ・ホーム・設定

| タスクID | タスク名 | 概要 | 実装内容 | 依存 | 優先度 | 完了条件 | 備考 |
|---|---|---|---|---|---|---|---|
| T4-1 | ホーム View 実装 | 記録入口と直近・クイックアクション | メイン CTA「今日のワークアウトを記録」、前回ルーティンで続ける、ルーティンを選ぶ、直近 2〜3 件、履歴・統計への導線 | T2-4, T1-8 | P0 | ホームから 2 タップで記録開始できる |  |
| T4-2 | 設定 View 実装 | 休憩デフォルト・About | 休憩デフォルト秒数、アプリ名・バージョン。必要なら種目マスタ・ルーティン管理への導線 | T2-13 | P0 | 休憩デフォルトを変更できる |  |
| T4-3 | 進歩提案の簡易ロジック実装 | 重量アップ/維持の提案 | 前回達成（全セット完了）なら「+2.5kg を試す」等。未達続きなら「維持で」。メモタグ「痛みあり」等があれば提案を出さない | T1-9, T1-10, T2-12 | P1 | 記録画面またはホームに控えめに表示できる | 押しつけにしない |
| T4-4 | デザイン統一（カラー・タイポ・余白） | 要件どおりの見た目 | AppTheme を反映、アクセント色・カード角丸・フォントサイズを統一 | T0-5, 全画面 | P0 | 画面間でトーンが揃う |  |
| T4-5 | ダーク/ライト対応 | 両テーマで見える | 色を Semantic または Asset で定義し、システムに追随 | T4-4 | P0 | テーマ切替で崩れない | 設定で固定は Phase 4 以降でも可 |
| T4-6 | アクセシビリティ最低限 | VoiceOver・ラベル | 主要ボタン・入力に accessibilityLabel。Dynamic Type は可能な範囲で | 全画面 | P1 | 読み上げで操作の意図が分かる |  |

---

## 4. ディレクトリ / ファイル構成案

```
App/
  KintoreApp.swift              # @main, modelContainer 注入
  ContentView.swift              # TabView ルート

Modules/
  Home/
    HomeView.swift
    HomeViewModel.swift
  Workout/
    WorkoutStartView.swift       # 今日のワークアウト開始
    WorkoutStartViewModel.swift
    WorkoutRecordView.swift
    WorkoutRecordViewModel.swift
  Routine/
    RoutineListView.swift
    RoutineListViewModel.swift
    RoutineEditView.swift
    RoutineEditViewModel.swift
  History/
    HistoryListView.swift
    HistoryListViewModel.swift
    SessionDetailView.swift
    SessionDetailViewModel.swift
    CalendarView.swift
    CalendarViewModel.swift
  Statistics/
    StatisticsView.swift
    StatisticsViewModel.swift
    ExerciseDetailView.swift    # 種目詳細/推移
    ExerciseDetailViewModel.swift
  Exercise/
    ExercisePickerView.swift    # 記録時の種目選択
    ExercisePickerViewModel.swift
    ExerciseMasterListView.swift # 設定からの種目マスタ一覧
    ExerciseMasterListViewModel.swift
  Settings/
    SettingsView.swift
    SettingsViewModel.swift

Core/
  Models/
    Exercise.swift
    WorkoutTemplate.swift
    WorkoutTemplateItem.swift
    WorkoutSession.swift
    WorkoutExercise.swift
    WorkoutSet.swift
    MemoTag.swift
    PersonalRecord.swift
    UserPreference.swift
  Repositories/
    ExerciseRepository.swift
    WorkoutTemplateRepository.swift
    WorkoutSessionRepository.swift
    UserPreferenceRepository.swift
  Services/
    LastRecordService.swift
    PersonalRecordService.swift
    TotalVolumeService.swift
    ProgressSuggestionService.swift  # Phase 4
    RestTimerManager.swift            # 目標時刻保持・通知
  Utilities/
    AppTheme.swift
    Date+Extensions.swift
    Formatters.swift

Resources/
  Assets.xcassets
  Localizable.strings (任意)
```

**Preview 用モック**: `Core/Models/` または `Modules/*/Preview/` に、モックデータを返す Repository のプロトコル実装を置く。例: `ExerciseRepositoryMock` で fetchAll が固定配列を返す。

**最初に作るファイル**: KintoreApp.swift → ContentView.swift（Tab）→ Core/Models/Exercise.swift から順にモデル → ExerciseRepository → 種目ピッカー・記録画面。

---

## 5. 画面ごとの実装タスク分解

### ホーム

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | メイン CTA、前回ルーティンで続ける、ルーティンを選ぶ、直近 2〜3 件（日付・種目数・所要時間）、履歴をもっと見る、今週サマリ（任意）、統計を見る |
| **ViewModel** | HomeViewModel |
| **必要な状態** | 直近セッション一覧、直近で使ったテンプレ（前回ルーティン）、今週の実施回数・総挙上（任意） |
| **必要なイベント** | 記録開始タップ、前回ルーティンで続けるタップ、ルーティン選択タップ、履歴タップ、統計タップ |
| **Repository/Service** | WorkoutSessionRepository.fetchRecent(3)、WorkoutTemplateRepository（直近 templateId から取得）、TotalVolumeService（今週）、LastRecordService は不要 |
| **難所** | 「前回のルーティン」を直近セッションの templateId で取る。テンプレ削除済みの場合は「新規で開始」に誘導 |
| **初版で省略可能** | 今週サマリ、統計への導線は後からでも可 |

---

### 今日のワークアウト開始画面

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | ルーティン一覧/カード、新規で開始、開始ボタン、開始時刻表示 |
| **ViewModel** | WorkoutStartViewModel |
| **必要な状態** | ルーティン一覧、選択中テンプレ（または nil＝新規） |
| **必要なイベント** | ルーティン選択、新規で開始、開始タップ |
| **Repository/Service** | WorkoutTemplateRepository.fetchAll()、開始時に Session 作成＋テンプレの種目順で WorkoutExercise を用意（保存は記録画面で） |
| **難所** | 新規で開始時は種目 0 の状態で記録画面を開き、最初の種目追加でピッカーを出す |
| **初版で省略可能** | 開始時刻の大きく出した表示は必須ではない |

---

### ワークアウト記録画面

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | 戻る・経過時間・終了、種目名・前回・ベスト、セットリスト、重量・回数入力、前回と同じ・+1rep・+2.5kg・-2.5kg、メモタグ、休憩タイマー、次の種目へ・終了 |
| **ViewModel** | WorkoutRecordViewModel |
| **必要な状態** | 現在セッション、現在種目インデックス、種目リスト、各種目のセット配列、前回情報・PR、編集中セット、休憩残り秒数・タイマー状態、メモタグ選択 |
| **必要なイベント** | 種目変更、セット追加、セット完了、前回と同じ、+1rep、±2.5kg、メモタグ選択、休憩スキップ/延長、次へ、終了 |
| **Repository/Service** | WorkoutSessionRepository（保存・更新）、LastRecordService、PersonalRecordService、RestTimerManager、MemoTag 固定リスト |
| **難所** | 複数種目の状態を 1 ViewModel で持つ設計。セッションを「編集中」と「保存済み」で扱い、終了時に endedAt と duration をセットして保存。休憩は種目ごと defaultRestSeconds。 |
| **初版で省略可能** | 自由文メモ 1 行は後からでも可 |

---

### 種目追加/編集画面（ピッカー・マスタ）

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | 検索欄、部位/器具フィルタ（任意）、お気に入り、種目リスト、カスタム追加、選択して戻る or 編集 |
| **ViewModel** | ExercisePickerViewModel / ExerciseMasterListViewModel |
| **必要な状態** | 種目一覧、検索クエリ、フィルタ、選択結果（ピッカー時） |
| **必要なイベント** | 検索入力、フィルタ変更、種目タップ（選択 or 編集）、新規追加 |
| **Repository/Service** | ExerciseRepository（fetchAll, search, fetchFavorites） |
| **難所** | 記録画面からは「選択して閉じる」、設定からは「編集・削除」と役割が違う。View を共有するか、別 View で同じ Repository を使うか。 |
| **初版で省略可能** | 器具タグフィルタ、お気に入りフィルタ |

---

### ルーティン一覧 / 編集画面

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | 一覧: カード（名前・種目数・最終実施日）、新規作成。編集: 種目リスト並び替え、種目追加・削除、名前・メモ、保存 |
| **ViewModel** | RoutineListViewModel、RoutineEditViewModel |
| **必要な状態** | 一覧: テンプレ一覧。編集: テンプレ、種目順配列 |
| **必要なイベント** | 一覧: タップで開始 or 編集、新規。編集: 並び替え、追加、削除、保存 |
| **Repository/Service** | WorkoutTemplateRepository |
| **難所** | 並び替えのドラッグ＆ドロップと order の更新。削除時は TemplateItem も削除。 |
| **初版で省略可能** | ルーティンのメモ欄、並び替えのアニメーション |

---

### 履歴一覧

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | 日付降順リスト、各行: 日付・ルーティン名・種目数・所要時間・総挙上（任意）、カレンダーへの導線 |
| **ViewModel** | HistoryListViewModel |
| **必要な状態** | セッション一覧（日付降順）、選択日（カレンダー連携用） |
| **必要なイベント** | 行タップでセッション詳細、カレンダー表示 |
| **Repository/Service** | WorkoutSessionRepository.fetchRecent または日付範囲、TotalVolumeService（セッション単位） |
| **難所** | 件数が多い場合のページングまたは仮リスト。初版は直近 100 件程度で十分。 |
| **初版で省略可能** | 総挙上を一覧行に表示しなくてもよい |

---

### カレンダー画面

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | 月グリッド、実施日マーク、月切替、日付タップ |
| **ViewModel** | CalendarViewModel |
| **必要な状態** | 表示月、その月の実施日 Set または [Date] |
| **必要なイベント** | 月切替、日付タップ → その日の履歴へ |
| **Repository/Service** | WorkoutSessionRepository で月範囲のセッションを取得し、startedAt の日付リストを生成 |
| **難所** | 月の初日・曜日揃え、Locale による週の開始曜日 |
| **初版で省略可能** | 月切替のアニメーション |

---

### 種目詳細/推移画面

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | 種目名、期間（1/3/6/全期間）、推移グラフまたは表、PR、直近セット一覧 |
| **ViewModel** | ExerciseDetailViewModel |
| **必要な状態** | 種目、期間、その種目の履歴（WorkoutExercise + Sets の時系列） |
| **必要なイベント** | 期間変更、種目変更（統計から複数種目を見る場合） |
| **Repository/Service** | WorkoutSessionRepository でセッションを取得し、種目でフィルタ。LastRecordService と同様のクエリで時系列取得。PersonalRecordService で PR 表示 |
| **難所** | グラフ用のデータ集計（日付・重量 or volume）。Swift Charts でシンプルに。 |
| **初版で省略可能** | 期間切替、グラフは「直近セットのリスト」のみでも可 |

---

### 統計画面

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | ワークアウト回数、総挙上重量、部位別頻度、PR 更新履歴、種目別サマリ |
| **ViewModel** | StatisticsViewModel |
| **必要な状態** | 今週/今月/全期間の回数・総挙上、部位別集計、PR 一覧、種目別実施回数・直近重量 |
| **必要なイベント** | 期間切替（今週/今月/全）、種目タップで種目詳細へ |
| **Repository/Service** | WorkoutSessionRepository、TotalVolumeService、PersonalRecordService、部位別集計 Service |
| **難所** | 部位別は Exercise.bodyPartTag とセッションの紐付け。種目別は「その種目が含まれるセッション数」で集計。 |
| **初版で省略可能** | 部位別グラフの見た目、種目別サマリの並び |

---

### 設定画面

| 項目 | 内容 |
|---|---|
| **実装対象 UI 要素** | 休憩デフォルト（秒）、種目マスタ、ルーティン管理、About（アプリ名・バージョン） |
| **ViewModel** | SettingsViewModel |
| **必要な状態** | defaultRestSeconds、ナビゲーション先（種目マスタ・ルーティン） |
| **必要なイベント** | 休憩秒数変更、種目マスタタップ、ルーティン管理タップ |
| **Repository/Service** | UserPreferenceRepository |
| **難所** | 特になし。シンプルに。 |
| **初版で省略可能** | テーマ切替、単位切替 |

---

## 6. データモデル実装タスク分解

| エンティティ | モデル定義 | リレーション | 永続化の注意 | サンプル/初期データ | マイグレーション |
|---|---|---|---|---|---|
| **Exercise** | @Model, id(UUID), name, bodyPartTag, equipmentTag, defaultRestSeconds, isPreset, isFavorite, sortOrder, createdAt | TemplateItem・WorkoutExercise から参照（id で） | プリセットは isPreset=true で削除禁止にするか、削除可能にするか仕様を決める | 初回起動でプリセット一括 insert | カラム追加時はデフォルト値を用意 |
| **WorkoutTemplate** | id, name, memo, sortOrder, createdAt, lastUsedAt | 1:N WorkoutTemplateItem。WorkoutSession が templateId で参照 | lastUsedAt はセッション開始時に更新 | ユーザーのみ作成 | 同上 |
| **WorkoutTemplateItem** | id, templateId, exerciseId(UUID), order | Template に属する。Exercise は id 参照 | テンプレ削除時に Item も削除（cascade または手動） | 同上 | 同上 |
| **WorkoutSession** | id, startedAt, endedAt, durationSeconds, workoutTemplateId?, createdAt | 1:N WorkoutExercise。Template は id 参照 | endedAt が nil の場合は「進行中」 | 記録画面で作成 | 同上 |
| **WorkoutExercise** | id, sessionId, exerciseId, order, memoTagIdsString または [String], freeMemo, createdAt | Session に属する。Exercise は id 参照。1:N WorkoutSet | memoTagIds は SwiftData で配列が使えなければ 1 文字列で保存 | 記録で追加 | 同上 |
| **WorkoutSet** | id, workoutExerciseId, weight, reps, order, completedAt | WorkoutExercise に属する | weight は Decimal または Double。reps は Int | 記録で追加 | 同上 |
| **MemoTag** | id(String), label, sortOrder | WorkoutExercise の memoTagIds が id を参照 | 初版は固定リスト。ユーザー追加は将来 | 初回投入またはコードで固定 | ほぼ変更なし |
| **PersonalRecord** | id, exerciseId, weight, reps, volume, achievedAt | Exercise を id で参照 | 1 種目 1 件で update する想定。volume で比較 | セット完了時に Service が insert/update | 同上 |
| **UserPreference** | defaultRestSeconds, weightUnit(将来), theme(将来) | なし | シングルトンとして 1 件だけ。存在しなければデフォルトで作成 | 初回はデフォルト値で 1 件作成 | 同上 |

---

## 7. Repository / Service / UseCase 分解

| 責務 | 置き場所 | 概要 | 実装タスク |
|---|---|---|---|
| 種目 CRUD | ExerciseRepository | 種目の追加・更新・削除・検索・一覧 | T1-6。fetchAll, fetchById, add, update, delete, search(name) |
| ルーティン CRUD | WorkoutTemplateRepository | テンプレと Item の保存・取得・削除、lastUsedAt 更新 | T2-1 |
| セッション保存 | WorkoutSessionRepository | セッションと WorkoutExercise/WorkoutSet の保存、取得、日付範囲取得 | T1-8 |
| 前回記録取得 | LastRecordService | exerciseId で直近の WorkoutExercise + Sets を返す | T1-9 |
| PR 判定・更新 | PersonalRecordService | セットの volume を比較し、上回れば PR を 1 件 insert/update | T1-10 |
| 総挙上計算 | TotalVolumeService | セッション・期間の weight×reps 合計 | T3-3 |
| 部位別頻度集計 | StatisticsService または TotalVolumeService 内 | bodyPartTag でグルーピングしてセッション数または種目回数を集計 | T3-7 |
| 進歩提案 | ProgressSuggestionService | 前回達成なら +2.5kg 等、未達続きなら維持。メモタグで抑制 | T4-3 |
| 休憩タイマー管理 | RestTimerManager（または ViewModel 内） | 目標終了時刻の保持、復帰時再計算、ローカル通知スケジュール | T2-9, T2-10, T2-11 |
| ユーザー設定 | UserPreferenceRepository または SettingsService | defaultRestSeconds の get/set、シングルトン取得 | T2-13 |

---

## 8. 状態管理と画面遷移設計

| 項目 | 方針 |
|---|---|
| **Tab 構成** | 4 Tab: ホーム、履歴、統計、設定。ルーティン一覧・開始画面・記録画面は Tab 外（プッシュまたはフルスクリーン） |
| **NavigationStack** | 各 Tab ごとに NavigationStack を 1 本持つ。ホーム → 開始 → 記録は push または fullScreenCover。種目ピッカー・ルーティン編集は sheet または push |
| **シート / フルスクリーン / プッシュ** | 記録画面は fullScreenCover（Tab を隠して没入）。種目ピッカーは sheet。ルーティン一覧は push（ホームまたは開始から）。ルーティン編集は push |
| **ViewModel のスコープ** | 各画面で 1 ViewModel。記録画面は 1 セッションを保持し、種目切替はインデックスで。子で持つ場合は Binding で渡す |
| **共有状態** | UserPreference は Environment に注入するか、シングルトンの Repository を @EnvironmentObject で渡す。テーマは .preferredColorScheme または Environment で |
| **UserPreference・テーマ** | 設定で変更した defaultRestSeconds は Repository 経由で永続化。テーマは初版はシステム追随でよい場合は .preferredColorScheme(nil) で十分 |
| **セッション中の状態保持** | 記録画面の ViewModel が「現在の WorkoutSession + WorkoutExercise[] + WorkoutSet[]」を保持。終了時に一括保存。アプリがキルされると進行中セッションは保存されない仕様でよい（初版）。 |

---

## 9. 実装順序の推奨

- **1 週目（基盤＋記録まで）**: Phase 0 完了 → Phase 1 のモデル定義（T1-1〜T1-5）→ ExerciseRepository とプリセット投入（T1-6, T1-7）→ WorkoutSessionRepository（T1-8）→ LastRecordService, PersonalRecordService（T1-9, T1-10）→ 種目ピッカー（T1-11）→ 記録画面最小版（T1-12）→ 前回・PR 表示とセット完了時の PR 更新（T1-13, T1-14）→ 開始画面から記録への遷移（T1-15）。ここまでで「種目を選んでセットを記録し、前回とベストが見える」が成立する。
- **2 週目（ルーティン・クイック・休憩）**: Phase 2 の TemplateRepository、ルーティン一覧・編集（T2-1〜T2-4）→ 記録画面の複数種目切替（T2-5）→ 前回と同じ・+1rep・±2.5kg（T2-6, T2-7）→ 前回セット数で初期表示（T2-8）→ 休憩タイマー（T2-9〜T2-11）→ メモタグ（T2-12）→ UserPreference（T2-13）。ここまでで「前回ルーティンで 2 タップ開始、クイック入力、休憩」が揃う。
- **3 週目（履歴・統計）**: Phase 3 の履歴一覧・セッション詳細・総挙上（T3-1〜T3-3）→ カレンダー（T3-4）→ 統計骨子・種目詳細（T3-5, T3-6）→ 部位別（T3-7）。ここまでで振り返りができる。
- **4 週目（仕上げ）**: Phase 4 のホーム（T4-1）、設定（T4-2）、進歩提案（T4-3）、デザイン統一・テーマ・アクセシビリティ（T4-4〜T4-6）。最後に動作確認と軽いテスト。

---

## 10. 難所・事故ポイント・先に決めるべき仕様

| 項目 | 内容 | 実装前の固定 |
|---|---|---|
| **PR 判定ルール** | volume で統一するか、最大重量を別 PR にするか | 本ドキュメント冒頭で「volume 最大 1 件」に固定済み |
| **前回取得の定義** | 種目単位か、ルーティン単位か、セッション単位か | 「種目単位で直近完了セッション内のその種目」に固定済み |
| **休憩タイマー** | バックグラウンドで Timer を止め、復帰時に目標時刻から再計算する | 目標時刻を UserDefaults 等に保存する仕様に固定済み |
| **SwiftData リレーション** | 逆参照・削除時の cascade。SwiftData は cascade を自動でしない可能性がある | テンプレ削除時は TemplateItem を明示削除。Session 削除時は子を先に削除するか、ドキュメントで確認 |
| **メモタグの持ち方** | [String] が SwiftData で使えるか | 使えなければ memoTagIdsString の 1 文字列で保存し、Service で [String] にパースする方針で固定済み |
| **単位変換** | 初版は kg 固定でよい | 固定済み |
| **ルーティンと実績の整合** | テンプレを編集したあと、過去セッションはそのまま。前回「値」は種目単位なので影響なし | 前回ルーティン再開は「テンプレの現在の種目順」で開始するだけ。値は LastRecordService で種目単位取得 |

**実装前に仕様を固定すること**: 上記 5 項目（PR・前回・メモタグ・単位・休憩）は本ドキュメント冒頭で固定済み。それ以外で迷ったら「種目単位・1 セッション＝1 回のワークアウト・前回は直近完了のみ」を原則にする。

---

## 11. 初版で削ってよいもの

以下のものは、UX と差別化の核を壊さず、リリース優先で削ってよい。

| 項目 | 理由 |
|---|---|
| 進歩提案の自動表示 | 記録・前回表示・ルーティンができていれば価値は出る。進歩提案は「あれば嬉しい」レベル。 |
| ホームの今週サマリ | 統計 Tab で代替できる。ホームは記録入口を最優先。 |
| 部位別頻度のグラフ | 数値だけでも可。グラフは Phase 4 以降。 |
| 種目詳細の期間切替（1/3/6 ヶ月） | 初版は「全期間」のみでも可。 |
| 設定のテーマ固定（常にダーク等） | システムに追随で十分なら後回し。 |
| 設定の単位切替 | kg 固定でリリースしてよい。 |
| 種目別デフォルト休憩の設定 UI | 全体デフォルトのみで可。種目マスタの defaultRestSeconds は後から表示してもよい。 |
| 自由文メモ 1 行 | タグだけで初版を出し、後から freeMemo を足す。 |
| カレンダーの月切替アニメーション | シンプルな切替で可。 |

**削ってはいけない**: 記録・前回表示・前回コピー・+rep/+kg・ルーティン適用・休憩タイマー・履歴一覧・基本統計（回数・総挙上・PR）・構造化メモタグ・ホームの記録 CTA と前回ルーティンで続ける。

---

## 12. 最終出力形式

### A. 開発着手順の短い要約

1. **Phase 0**: プロジェクト作成、Tab ルート、SwiftData の modelContainer 登録、ディレクトリとプレースホルダ。
2. **Phase 1**: Exercise をはじめ全 SwiftData モデルを定義し、ModelContainer に登録 → ExerciseRepository とプリセット投入 → WorkoutSessionRepository、LastRecordService、PersonalRecordService → 種目ピッカー → ワークアウト記録画面（1 種目・複数セット）に前回値・PR 表示とセット完了時の PR 更新を組み込む → 開始画面から記録へ遷移。ここまでで「記録して前回が見える」が動く。
3. **Phase 2**: ルーティン CRUD、開始画面でルーティン選択・前回ルーティンで続ける、記録画面で複数種目切替 → 前回と同じ・+1rep・±2.5kg、休憩タイマー（目標時刻保持・復帰時再計算・通知）、メモタグ、UserPreference。ここまでで「速く記録・続けやすい」が揃う。
4. **Phase 3**: 履歴一覧・セッション詳細・総挙上、カレンダー、統計・種目詳細。ここまでで振り返りができる。
5. **Phase 4**: ホーム、設定、進歩提案（簡易）、デザイン統一。リリース可能な状態にする。

### B. Cursor 向け次プロンプト候補

1. **Phase 1 の SwiftData モデル実装**: 「要件定義書と開発タスク分解書に基づき、Exercise, WorkoutSession, WorkoutExercise, WorkoutSet, WorkoutTemplate, WorkoutTemplateItem, MemoTag, PersonalRecord, UserPreference の SwiftData @Model を Swift で実装してください。リレーションと型（UUID, Decimal, Date 等）は分解書のデータ設計に従ってください。」

2. **WorkoutRecordView の SwiftUI 実装**: 「開発タスク分解書の『ワークアウト記録画面』の実装対象 UI 要素に従い、1 種目・複数セットの記録ができる WorkoutRecordView と WorkoutRecordViewModel を SwiftUI と MVVM で実装してください。前回値・PR 表示、セットリスト、重量・回数入力、セット完了ボタンを含め、LastRecordService と PersonalRecordService を呼び出す形にしてください。」

3. **Repository 層のインターフェースと実装**: 「ExerciseRepository と WorkoutSessionRepository のプロトコル（またはクラス）を定義し、SwiftData の ModelContext を使った実装を書いてください。ExerciseRepository は fetchAll, fetchById, add, update, delete, search を、WorkoutSessionRepository は save, fetchRecent, fetchByDateRange を実装してください。」

4. **前回記録取得 LastRecordService**: 「開発タスク分解書の『前回記録の定義』に従い、exerciseId を受け取り、直近の完了セッションに含まれるその種目の WorkoutExercise と WorkoutSet を返す LastRecordService を Swift で実装してください。SwiftData の ModelContext を使用します。」

5. **休憩タイマー（目標時刻・復帰時再計算・通知）**: 「セット完了時に休憩を開始し、目標終了時刻（Date）を保持、アプリ復帰時に現在時刻と比較して残り時間を再計算する RestTimerManager と、終了時に 1 回だけローカル通知を送る処理を Swift で実装してください。UserDefaults に目標時刻を保存する方針でよいです。」

以上で、SwiftUI 実装のための開発タスク分解書とする。
