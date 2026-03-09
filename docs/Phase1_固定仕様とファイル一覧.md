# Phase 1 固定仕様とファイル一覧

## 1. 今回固定する仕様

### 1.1 PR判定ルール
- **採用**: 同一種目で **volume（weight × reps）が最大の 1 セット** を PR として 1 件保持する。
- **更新**: セット完了時に、その種目の既存 PR の volume と比較し、上回れば PersonalRecord を insert または update。
- 重量・回数のどちらかが nil のセットは volume 計算から除外（PR 更新しない）。

### 1.2 前回記録の定義
- **前回**: 同一種目（exerciseId）について、**endedAt が存在する（完了した）WorkoutSession** に紐づく WorkoutExercise のうち、**セッションの endedAt が最も新しい 1 件**。その WorkoutExercise の WorkoutSet を「前回のセット」として使用。
- 返す値: 前回の weight / reps / セット数 / 実施日。画面用 DTO で返す。

### 1.3 メモタグの保持方式
- **WorkoutExercise**: `memoTagIdsString: String` で保持（カンマ区切り、例: `"form_bad,pain"`）。SwiftData で配列を避け、Service 層で `[String]` にパースする。
- **MemoTag マスタ**: SwiftData の MemoTag で id（String）, label, sortOrder を保持。初回起動時に Seed で投入。

### 1.4 重量単位の扱い
- **初版**: kg 固定。UserPreference に weightUnit は持たせるが、初版では "kg" のみ使用し、UI では単位切替を出さない。

### 1.5 休憩タイマー用デフォルト秒数
- **UserPreference.defaultRestSeconds**: アプリ全体のデフォルト（初版 90 秒）。
- **Exercise.defaultRestSeconds**: 種目別。nil の場合は UserPreference の値を使用。種目別上書きは初版では設定 UI を出さず、モデルだけ用意。

---

## 2. 今回作るファイル一覧

```
kintore/
├── docs/
│   └── Phase1_固定仕様とファイル一覧.md   # 本ファイル
├── App/
│   ├── KintoreApp.swift                  # ModelContainer + AppBootstrapper 呼び出し
│   └── ContentView.swift                 # プレースホルダ（Phase 2 で Tab 等に差し替え）
├── Core/
│   ├── Models/
│   │   ├── Exercise.swift
│   │   ├── WorkoutTemplate.swift
│   │   ├── WorkoutTemplateItem.swift
│   │   ├── WorkoutSession.swift
│   │   ├── WorkoutExercise.swift
│   │   ├── WorkoutSet.swift
│   │   ├── MemoTag.swift
│   │   ├── PersonalRecord.swift
│   │   └── UserPreference.swift
│   ├── Seed/
│   │   ├── DefaultExercisesSeed.swift
│   │   ├── DefaultMemoTagsSeed.swift
│   │   └── AppBootstrapper.swift
│   ├── Repositories/
│   │   ├── ExerciseRepository.swift
│   │   ├── WorkoutRepository.swift
│   │   ├── TemplateRepository.swift
│   │   └── SettingsRepository.swift
│   ├── Services/
│   │   ├── PreviousRecordService.swift
│   │   ├── WorkoutStatsService.swift
│   │   └── PersonalRecordService.swift
│   ├── Utilities/
│   │   └── MemoTagIdsHelper.swift      # 文字列 ⇔ [String] 変換
│   └── ModelContainerFactory.swift
```

以上を Phase 1 で生成する。
