# Phase 2 固定仕様とファイル一覧

## 1. 今回固定する仕様

### 1.1 ホームから記録開始までの遷移方式
- **ホーム** → 「今日のワークアウトを記録」タップ → **WorkoutStartView**（プッシュ）。
- WorkoutStartView で「新規で開始」またはルーティン選択 → **WorkoutRecordView**（fullScreenCover で表示し、Tab を隠す）。
- 記録画面は 1 本の NavigationStack の外で fullScreenCover にする。

### 1.2 ワークアウト記録中の状態保持方式
- **永続モデルは編集に使わない**。画面は **WorkoutSessionDraft / WorkoutExerciseDraft / WorkoutSetDraft** のみを保持・編集する。
- 開始時に Draft を 1 つ作成（新規は空の種目リスト、ルーティン選択時はテンプレから種目をコピーして Draft に反映）。
- 保存時に Draft から永続モデル（WorkoutSession / WorkoutExercise / WorkoutSet）を生成し、Repository 経由で保存。

### 1.3 セット完了の定義
- ユーザーが「完了」トグルを ON にした時点で、そのセットを **完了** とする。
- 完了時に `completedAt = Date()` をセット。重量・回数が両方入力されていれば PR 更新の対象とする。

### 1.4 前回記録の表示粒度
- 種目ごとに **前回の 1 セット目の重量・回数** と **前回のセット数**、**最終実施日** を表示する。
- 記録画面では「前回 40kg × 10 × 3 セット 最終 3/6」のような簡易表記でよい。

### 1.5 セッション保存タイミング
- ユーザーが「ワークアウトを終了」をタップし、確認後に **その時点で** 保存する。
- 終了時に `endedAt = Date()`、`durationSeconds = Int(endedAt - startedAt)` をセットしてから保存。
- 保存後は fullScreenCover を dismiss し、ホームまたは履歴に戻る。

### 1.6 今回未実装にするもの
- 休憩タイマー
- 「前回と同じ」「+1rep」「+2.5kg」クイックボタン
- 構造化メモタグ（WorkoutExercise の freeMemo のみ対応）
- 進歩提案
- カレンダー画面
- カスタム種目追加（種目マスタからの追加は将来）
- 「前回のルーティンで続ける」はボタンだけ用意し、動作は「新規で開始」と同様でも可

---

## 2. 今回作るファイル一覧

```
App/
  AppRootView.swift
  MainTabView.swift
  KintoreApp.swift          # 修正: AppRootView をルートに

Modules/
  Home/
    HomeView.swift
    HomeViewModel.swift
  Workout/
    WorkoutStartView.swift
    WorkoutStartViewModel.swift
    WorkoutRecordView.swift
    WorkoutRecordViewModel.swift
    WorkoutSessionDraft.swift
    WorkoutExerciseDraft.swift
    WorkoutSetDraft.swift
  Exercise/
    ExercisePickerView.swift
    ExercisePickerViewModel.swift
  History/
    HistoryListView.swift
    HistoryListViewModel.swift
    SessionDetailView.swift

Components/
  PrimaryButton.swift
  SectionCard.swift
  MetricChip.swift
  EmptyStateView.swift
  SetRowView.swift

Core/Repositories/
  WorkoutRepository.swift   # 追記: saveSession(from:exerciseLookup:template:)

Core/Utilities/
  AppFormatters.swift       # 追加: 日付・重量・時間フォーマット
```

---

## 4. 既存 Phase 1 への追加修正

### WorkoutRepository.swift
- **プロトコル**: `saveSession(from draft: WorkoutSessionDraft, exerciseLookup: [UUID: Exercise], template: WorkoutTemplate?) throws -> WorkoutSession` を追加。
- **実装**: Draft から `WorkoutSession` / `WorkoutExercise` / `WorkoutSet` を生成して insert し、`modelContext.save()` する。PR 更新は呼び出し側（WorkoutRecordViewModel）で実施。

---

## 5. 補足

### Phase 2 完了後に作るべきもの
- 休憩タイマー（セット完了時自動開始・目標時刻保持・通知）
- 「前回と同じ」「+1rep」「+2.5kg」クイックボタン
- 構造化メモタグ選択 UI
- 進歩提案の簡易表示
- カレンダー画面・統計画面・設定画面
- デザイン仕様（カラー・タイポ）の適用

### 動作確認チェック項目
1. 起動 → ホームで「今日のワークアウトを記録」→ 開始画面 → 「新規で開始」→ 記録画面が開くこと。
2. 記録画面で「種目を追加」→ 種目ピッカーで選択 → 種目が追加され、前回記録があれば表示されること。
3. 重量・回数入力 → セット完了トグル → 「+ セット追加」でセットが増えること。
4. 「終了」→ 「保存して終了」→ モーダルが閉じ、ホームに戻ること。
5. ホームの直近履歴に保存したセッションが表示されること。
6. 履歴タブ or 「履歴をもっと見る」→ 一覧 → セッションタップで詳細（日付・所要時間・総挙上・種目・セット）が表示されること。
7. ルーティンが存在する場合、開始画面でルーティン選択 → 記録画面に種目が並んでいること。
