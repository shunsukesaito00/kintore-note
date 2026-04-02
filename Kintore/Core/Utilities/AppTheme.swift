// File: Core/Utilities/AppTheme.swift
// デザイン統一：カラー・角丸・余白・タイポを1か所で定義。STRONG 寄り・落ち着いたトーン。
//
// MARK: Phase 1 — デザイン基盤（トークンとルール）
//
// **完了条件（新規UI）**: 原則として本 enum のトークンのみ参照。マジックナンバー禁止。
//
// --- 角丸（S / M / L）---
// | サイズ | 値   | 主な用途 |
// |--------|------|----------|
// | S      | 10pt | `chipCornerRadius` — チップ・バッジ |
// | M      | 14pt | `buttonCornerRadius` / `inputCornerRadius` — CTA・入力ブロック |
// | L      | 16pt | `cardCornerRadius` — SectionCard・appCardStyle |
// 互換: `cornerRadiusSmall` / `Medium` / `Large` が S/M/L のエイリアス。
//
// --- 余白（xs〜xl）---
// | トークン   | pt |
// |------------|-----|
// | spacingXS  | 4   |
// | spacingSM  | 8   |
// | spacingMD  | 12  |
// | spacingLG  | 16  |
// | spacingXL  | 24  |
// | spacingXXL | 32  |
// セマンティック: `xs` … `xl` が同じ値の別名。
//
// --- Elevation 0〜2（影の設計と実装トークン）---
// | レベル | 見え方 | 参照 |
// |--------|--------|------|
// | E0     | 影なし（フラット） | リスト行デフォルト等 |
// | E1     | ごく弱い浮き | `chipShadow*` / `secondaryButtonShadow*` |
// | E2     | カード・主CTA | `cardShadow*` / `primaryButtonShadow*` |
//
// --- サーフェス階層（使い分け）---
// | 層 | トークン | 用途 |
// |----|----------|------|
// | L0 | `appBackground` | 画面全体（systemGroupedBackground） |
// | L1 | `cardBackground` | 標準カード・リスト上パネル（secondarySystemGroupedBackground） |
// | L2 | `memoRecordSurface` | 一段明るい面・記録ブロック（systemBackground） |
// | L3 | `memoInputCellFill` / `inputFill` | 入力セル・テキストフィールド下地 |
//
// --- タイポ階層（新規はこの表に従う）---
// | 画面要素 | トークン（例） |
// |----------|----------------|
// | ナビ中央タイトル・強い見出し | `headlineFont` / `screenTitleFont` |
// | セクション見出し・カードタイトル | `sectionTitleFont` / `title3Font` |
// | 本文 | `bodyTypographyFont` / `bodySecondaryFont` |
// | キャプション・注釈 | `captionTypographyFont` |
// | 数値強調（重量・回数・統計） | `emphasizedNumberFont` / `metricFont` / `.rounded` 系 |
// | ボタンラベル | `buttonLabelFont` |
// | チップ | `chipLabelFont` |
//
// --- カード表現方針 ---
// **ヘアライン枠（0.5pt）＋軽い下方向シャドウ** を標準。`SectionCard` / `appCardStyle` が参照。
// 枠線のみ・影のみの単独運用はしない（例外はプレミアムバナー等、コード上コメントで明示）。
//
// --- 既存名の移行方針 ---
// `cardCornerRadius` 等の **既存名を正** とする。新規追加はここに集約し、重複定数は作らない。
//
// MARK: Phase 7 — ルール化と維持（リリース品質）
//
// --- 7.1 新規画面チェックリスト（必須）---
// 1. **トークン**: 色・余白・角丸・影・タイポは `AppTheme` のみ（マジックナンバー禁止）。
// 2. **コンポーネント**: カードは `SectionCard` / `appCardStyle` / `appSubtleElevatedShadow`。主CTA `PrimaryButton`、副 `SecondaryActionButton`。
// 3. **シェル**: タブ直下ルートは `appTabRootChrome()`。モーダルシートは `standardSheetChrome()` を検討。
// 4. **A11y**: 主要ボタン・ナビアイコン・タブに `accessibilityLabel`（必要なら `Hint`）。装飾のみの画像は `accessibilityHidden(true)`。
// 5. **Dynamic Type**: ナビ中央タイトルは `dynamicTypeNavigationPrincipal()`。長い見出し・カードタイトルは `lineLimit` + 折り返しを検討。
// 6. **コントラスト**: アクセント上の白文字は `PrimaryButton` 等の既定のみ。二次テキストは `secondaryText` / `tertiaryText` を使用。
// 7. **Reduce Motion**: 状態変化のアニメは `animationTabTransition` / `animationOverlay` / `animationButtonPress` 等（**Phase 8**）を使い、`accessibilityReduceMotion` を参照する。
//
// --- 7.2 意図的なスタイル例外（変更時は仕様とセットで見直す）---
// | 領域 | ファイル・コンポーネント | 理由 |
// |------|---------------------------|------|
// | グラフ破線 | `ExerciseDetailView`, `GrowthExerciseTab` 等の `StrokeStyle(dash:)` | 系列識別。影トークンとは別レイヤー。 |
// | グラフ軸・エリア | `ModernChartStyle` + `modernChart*Axes()` | 軸は `AppTheme` のテキスト色。ライン下塗りは `lineAreaGradient(for:)`。 |
// | MEMO 記録ナビ | `WorkoutRecordView`, `WorkoutSessionFlowView`, `MemoNavBarWeightUnitPicker` | 青ヘッダ・白文字は記録専用の視認性優先。 |
// | 部位一覧シート | `BodyPartExerciseListView` | `memoNavBarBackground` + ダークツールバー。 |
// | プレミアム訴求 | `PremiumCTAView`, 成長タブのピッカー制限 | マーケ強調。可能なら `accentSoft` への寄せを検討。 |
// | エクスポート | `ExportService`, `CSVWorkoutRangeExportSheet`, `SettingsView` 共有 | ファイル出力・共有 UI はシステム寄り。 |
// | 共有 | `ShareSheet`, `ShareCardComposer`, `SessionDetailView` 共有プレビュー | UIActivity 前提。 |
// | オンボーディング | `OnboardingView` | フルスクリーン導線。別デザイン許容。 |
// | Watch / Widget | `KintoreWatch`, `KintoreWidget` | プラットフォーム制約。 |
// | 弱いパネル影 | `subtlePanelShadow*`, `appSubtleElevatedShadow` | 履歴ストリーク・開始画面リストブロック等 E1。 |
// | セット行入力 | `SetRowView` | 入力密度・キーボード UX 優先。角丸は `memoSetFieldCornerRadius` 系。 |
//
// --- 7.3 リリース前スモーク（Phase 3〜5 回帰・手動）---
// **シェル**: 4タブ往復、ダークモードでタブバー・ナビが読める。**ホーム**: 記録フローへ遷移、週目標シート。**記録**: セット入力・保存・完了サマリー・休憩オーバーレイ。**履歴**: カレンダー・セッション詳細。**成長**: 3タブスワイプ・共有。**設定**: Form スクロール・CSV エクスポート・サブ画面1つ。**A11y**: VoiceOver でタブ・保存・閉じるが辿れる。**大文字**: 最大サイズでホームタイトル・記録ナビが切れない。
//
// MARK: Phase 6 — 実装指針（コードとの対応）
// - **モーション**: タブ・記録・オンボは **Phase 8** の `animationTabTransition` / `animationOverlay` / `animationOnboardingPage` 等（`reduceMotion` 連動）。直参照の `animationQuick` は原則使わない。
// - **シート**: `standardSheetChrome()`（ドラッグインジケータ + 角丸）。
// - **Dynamic Type**: `dynamicTypeNavigationPrincipal()` をホームのナビ中央に適用。`SectionHeaderView` は見出しとして複数行化。
// - **VoiceOver**: タブ・成長の共有ボタン・ホーム設定に Hint を追加。既存の記録ツールバー・セット行ラベルと併用。
// - **コントラスト**: ライト/ダークで `secondaryLabel` 系トークンを使用。記録画面の白上コントラストは `memoNavBar` 系に統一。
//
// MARK: Phase 8 — Reduce Motion と拡張ターゲットの一貫性
// - **Reduce Motion**: 設定 › アクセシビリティ › **動作を減らす** がオンのとき、`animationTabTransition` / `animationButtonPress` 等で **短い線形または easeOut** に差し替え。`PrimaryButton` / `SecondaryActionButton` は **スケール変形を行わない**。
// - **適用箇所**: `MainTabView`, `AppRootView`, `GrowthDashboardView`, 記録フロー（PR バナー・休憩・並び替え）, `WorkoutCompleteSummaryView`（PR 祝い）, `OnboardingView`（ページドット）。
// - **Widget**: `KintoreWidget` はメインターゲットの `AppTheme` を参照できないため、**アクセント RGB は `accentUIColor` のライト値（0.29, 0.56, 0.85）と同期**すること（ソース内コメント参照）。
// - **Watch**: `WatchBrandColors` + `WatchContentView.tint`（Phase 9）。RGB は Widget と共通。

// MARK: Phase 9 — モダンUIの残差解消（クロージャ）
// - **オンボーディング**: `withAnimation` を `animationOnboardingPage(reduceMotion:)` に統一。
// - **Watch**: `.tint(WatchBrandColors.accent)` で watchOS の強調色を iPhone のライトアクセントに揃える。
// - **Phase 2.4（任意）**: 1行カードの共通 `Row` 化はリファクタ規模が大きいためスキップ可。

import SwiftUI
import UIKit

enum AppTheme {

    /// UserDefaults key for weight unit (kg/lb). Synced from UserPreference for display.
    static let weightUnitStorageKey = "weight_unit"

    /// UserDefaults key for app theme (system/dark/light).
    static let appThemeStorageKey = "app_theme"

    /// セット行で種別の列・詳細メニューを隠すシンプル入力モード
    static let simpleSetInputStorageKey = "kintore.simpleSetInputMode"

    /// セット完了時に自動で休憩タイマーを開始する（既定 true）。オフで手動開始のみ。
    static let autoStartRestOnSetCompleteKey = "kintore.autoStartRestOnSetComplete"

    // MARK: - 余白（全画面で統一）
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // MARK: - MEMO 参照アプリ寄せ（可読性・情報密度）
    /// ブロック間（ホーム縦並び・記録エディタ内セクション間）。参照は 12pt 前後が多い。
    static let memoSectionGap: CGFloat = 12
    /// カード内の標準パディング（16 の代わりに詰める）
    static let memoCardPadding: CGFloat = 12
    /// リスト行の縦パディング（種目名行など）
    static let memoListRowPaddingV: CGFloat = 10
    /// セット表 1 行の縦余白
    static let memoSetRowPaddingV: CGFloat = 3
    /// MEMO グリッドの入力欄の最小高さ（単位インライン化でやや低めでも主役は維持）
    static let memoStrengthGridInputMinHeight: CGFloat = 34
    /// セット数値ブロック直下〜セットメモ行までの間隔
    static let memoSetBlockToMemoSpacing: CGFloat = 2
    /// 記録画面・種目カード同士の縦間隔（やや詰める）
    static let recordExerciseBlockSpacing: CGFloat = 10
    /// 種目ピッカー・部位カード内の種目行の縦パディング（参照の「行が高い」）
    static let memoPickerExerciseRowPaddingV: CGFloat = 14
    static let memoSetRowPaddingH: CGFloat = 6
    /// 見出し直下のサブテキストとの隙間
    static let memoTitleSubtitleGap: CGFloat = 2
    /// 前回パネル・ユーティリティ行の内側
    static let memoInsetPadding: CGFloat = 10
    /// セットメモ・休憩秒数入力など（6pt 前後）
    static let memoCompactFieldPaddingV: CGFloat = 6

    /// セマンティック別名（xs, sm, md, lg, xl）
    static var xs: CGFloat { spacingXS }
    static var sm: CGFloat { spacingSM }
    static var md: CGFloat { spacingMD }
    static var lg: CGFloat { spacingLG }
    static var xl: CGFloat { spacingXL }

    // MARK: - タップ領域
    static let touchTargetPrimary: CGFloat = 56
    static let touchTargetSecondary: CGFloat = 48
    static let touchTargetMin: CGFloat = 44

    // MARK: - 角丸（small / medium / large — Phase 1）
    /// カード・セクションコンテナ
    static let cardCornerRadius: CGFloat = 16
    /// 主 CTA・セカンダリボタン・入力ブロックの外周
    static let buttonCornerRadius: CGFloat = 14
    /// バッジ・フィルタチップ
    static let chipCornerRadius: CGFloat = 10
    /// テキストフィールド・エディタブロック（ボタンと視覚的に揃える）
    static let inputCornerRadius: CGFloat = 14

    static var cornerRadiusSmall: CGFloat { chipCornerRadius }
    static var cornerRadiusMedium: CGFloat { buttonCornerRadius }
    static var cornerRadiusLarge: CGFloat { cardCornerRadius }

    // MARK: - カラー（STRONG 寄り・1アクセント・落ち着いた背景）

    /// 画面全体背景（全対象画面で統一・少しトーンを落としたグレー）
    static var appBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    /// カード背景（白またはやや明るいサーフェス）
    static var cardBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    /// カード枠線（薄く）
    static var cardBorder: Color {
        Color(uiColor: .separator).opacity(0.5)
    }

    /// カード輪郭の線幅（ヘアライン）
    static let cardStrokeWidth: CGFloat = 0.5

    /// メインアクセント（STRONG 風ブルー・主CTA・選択状態のみ）
    static var accent: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.38, green: 0.62, blue: 0.92, alpha: 1)
            } else {
                return UIColor(red: 0.29, green: 0.56, blue: 0.85, alpha: 1)
            }
        })
    }

    /// アクセントの薄い背景（チップ・バッジ・セカンダリボタン背景）
    static var accentSoft: Color {
        accent.opacity(0.12)
    }

    /// サマリー用ピル背景（筋トレメモ風・淡い青）
    static var pillBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.22, green: 0.32, blue: 0.48, alpha: 0.55)
            } else {
                return UIColor(red: 0.88, green: 0.93, blue: 0.99, alpha: 1)
            }
        })
    }

    /// サマリー用ピル文字色
    static var pillForeground: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.65, green: 0.78, blue: 0.98, alpha: 1)
            } else {
                return UIColor(red: 0.18, green: 0.42, blue: 0.72, alpha: 1)
            }
        })
    }

    /// 種目カード内タグ（ライトブルー系）
    static var tagChipBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.25, green: 0.38, blue: 0.55, alpha: 0.55)
            } else {
                return UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1)
            }
        })
    }

    static var tagChipForeground: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.85, green: 0.9, blue: 0.98, alpha: 1)
            } else {
                return UIColor(red: 0.2, green: 0.38, blue: 0.62, alpha: 1)
            }
        })
    }

    /// 従来の accentTintBackground と同一（互換用）
    static var accentTintBackground: Color { accentSoft }

    /// セカンダリアクセント（深め・他画面互換のため残す）
    static var accentSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.25, green: 0.45, blue: 0.75, alpha: 1)
            } else {
                return UIColor(red: 0.21, green: 0.45, blue: 0.71, alpha: 1)
            }
        })
    }

    /// CTA・装飾用グラデ（Onboarding/Statistics 等・ホーム/開始/記録では使わない）
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// テキスト: メイン
    static var primaryText: Color { Color.primary }

    /// テキスト: セカンダリ
    static var secondaryText: Color { Color.secondary }

    /// テキスト: 補助（キャプション・注釈）
    static var tertiaryText: Color {
        Color(uiColor: .tertiaryLabel)
    }

    /// 区切り線
    static var separator: Color {
        Color(uiColor: .separator)
    }

    /// 破壊的操作（削除・キャンセル等・必要時のみ）
    static var destructive: Color { Color.red }

    /// 成功・完了（必要時のみ）
    static var success: Color { accent }

    /// カード用ソフト縦グラデ（廃止推奨・フラット化のため cardBackground を推奨）
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .secondarySystemGroupedBackground),
                Color(uiColor: .tertiarySystemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// カード用やや明るい/暗い面（elevated）
    static var surfaceElevated: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    /// 入力エリア・リスト行用の一段暗い面
    static var surfaceTertiary: Color {
        Color(uiColor: .tertiarySystemGroupedBackground)
    }

    /// 入力フィールド背景（薄いフィル）
    static var inputFill: Color {
        Color(uiColor: .tertiarySystemFill)
    }

    // MARK: - 筋トレメモ寄せ（フラット・白ベース・枠なし入力）

    /// 記録ブロックの下地（ページより一段明るい白）
    static var memoRecordSurface: Color {
        Color(uiColor: .systemBackground)
    }

    /// セット行の入力セル（枠線なし・タップしやすいフラット）
    static var memoInputCellFill: Color {
        Color(uiColor: .tertiarySystemFill)
    }

    /// 種目ヘッダー（青帯ではなくフラットな見出し）
    static var memoExerciseHeaderBackground: Color {
        Color(uiColor: .systemBackground)
    }

    /// 種目名ヘッダー用（STRONG 風・青系・重すぎない）
    static var exerciseHeaderBackground: Color {
        accent.opacity(0.18)
    }

    // MARK: - 記録フロー用アクセント（青 `accent` に統一）

    /// ナビ・サマリー帯・種目ヘッダ・セット行のアクセント色（常に青系）
    static func memoSessionAccentColor(useMemoRed: Bool = false) -> Color { accent }

    /// ワークアウト開始／記録のナビバー背景
    static func memoNavBarBackground(useMemoRed: Bool = false) -> Color { accent }

    /// ナビバー上のタイトル・ボタン（白）
    static var memoNavBarForeground: Color { Color.white }

    /// 部位カード先頭の帯・記録サマリー帯など
    static func memoSectionHeaderBackground(useMemoRed: Bool = false) -> Color { accent }

    /// 記録画面のサマリー行の下地（4枠の上に載せる帯）
    static func memoSummaryBarBackground(useMemoRed: Bool = false) -> Color { accent }

    /// 種目名ヘッダー（不透明帯・白文字）— 記録画面の種目カード用
    static func memoSolidExerciseHeaderBackground(useMemoRed: Bool = false) -> Color { accent }

    static var memoNavBarBackground: Color { accent }

    static var memoSummaryBarBackground: Color { accent }

    static var memoSolidExerciseHeaderBackground: Color { accent }

    /// ホーム帯など
    static var memoSectionHeaderBackground: Color { accent }

    /// 記録ナビバー（やや明るい青・白文字用）
    static var memoNavigationBarFill: Color {
        Color(uiColor: UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.32, green: 0.48, blue: 0.72, alpha: 1)
            }
            return UIColor(red: 0.42, green: 0.68, blue: 0.94, alpha: 1)
        })
    }

    /// 筋トレメモ風・右下 FAB（種目追加）
    static var memoFABGreen: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.2, green: 0.75, blue: 0.45, alpha: 1)
            } else {
                return UIColor(red: 0.18, green: 0.72, blue: 0.42, alpha: 1)
            }
        })
    }

    /// 入力欄の枠線（入力領域を明確にする）
    static var inputFieldBorder: Color {
        Color(uiColor: .separator).opacity(0.8)
    }

    // MARK: - タイポグラフィ（見出し・本文・補助の階層を統一）

    static let largeTitleFont = Font.largeTitle.weight(.heavy)
    static let titleFont = Font.title2.weight(.bold)
    static let title3Font = Font.title3.weight(.semibold)
    static let headlineFont = Font.headline
    static let subheadlineFont = Font.subheadline
    static let bodyFont = Font.body
    static let bodySemiboldFont = Font.body.weight(.semibold)
    /// Dynamic Type に追従（旧 22pt 固定）
    static let metricFont = Font.title2.weight(.bold)
    static let captionFont = Font.caption
    static let footnoteFont = Font.footnote
    /// Dynamic Type に追従（旧 18pt 固定）
    static let numericEmphasisFont = Font.title3.weight(.semibold)
    /// 表ヘッダー・種別/RPE等の小さなラベル（STRONG風に控えめに）
    static let smallCaptionFont = Font.caption2.weight(.medium)

    /// 画面タイトル（ナビゲーション等）
    static var screenTitleFont: Font { titleFont }

    /// セクション見出し
    static var sectionTitleFont: Font { title3Font }

    /// カードタイトル
    static var cardTitleFont: Font { title3Font }

    /// 本文
    static var bodyTypographyFont: Font { bodyFont }

    /// 本文サブ（やや小さめ）
    static var bodySecondaryFont: Font { subheadlineFont }

    /// 補助テキスト
    static var captionTypographyFont: Font { captionFont }

    /// 数字強調（重量・回数等）
    static var emphasizedNumberFont: Font { numericEmphasisFont }

    /// 記録画面上部4枠サマリーの数値（入力行と同程度の高さに収める）
    static var sessionSummaryValueFont: Font {
        Font.subheadline.weight(.semibold)
    }

    /// 記録画面ナビ以外のコンパクトラベル（保存ボタン等）
    static var memoRecordCompactTitleFont: Font {
        Font.subheadline.weight(.semibold)
    }

    /// 記録ナビ中央の種目名（やや大きめ）
    static var memoRecordNavigationTitleFont: Font {
        Font.body.weight(.semibold)
    }

    /// MEMO グリッドの種別略称（重量・回数の入力と同じ段の太さ）
    static var memoSetTypeAbbreviationFont: Font {
        Font.system(.body, design: .rounded).weight(.medium)
    }

    /// ホーム青帯の負荷トン数（7日/28日）
    static var homeHeroVolumeFont: Font {
        Font.system(.title, design: .rounded).weight(.bold)
    }

    /// ボタンラベル（主CTA）
    static var buttonLabelFont: Font { headlineFont }

    // MARK: - 筋トレメモモデル寄せタイポ（セッション詳細・表）

    /// セッション詳細の日付（大きく太く）— Dynamic Type 対応
    static var sessionDateTitleFont: Font {
        Font.title2.weight(.bold)
    }

    /// 種目カード内の種目名
    static var exerciseNameInCardFont: Font {
        Font.title3.weight(.bold)
    }

    /// 記録画面・種目ヘッダー帯の種目名（セット表と同じ帯の高さ感に合わせる）
    static var exerciseRecordHeaderTitleFont: Font {
        Font.subheadline.weight(.semibold)
    }

    /// 種目カード内サブ（○○kg 挙上）
    static var exerciseVolumeSubtitleFont: Font {
        Font.footnote
    }

    /// 表ヘッダー「セット」「kg」「回」
    static var tableHeaderLabelFont: Font {
        Font.caption.weight(.medium)
    }

    /// MEMO/記録のセット列表ヘッダー（入力数字の body より一段小さめで統一感）
    static var memoSetTableHeaderFont: Font {
        Font.footnote.weight(.semibold)
    }

    /// 前回記録パネル本文（「前回」行・セット行。表見出しは除く）
    static var previousRecordPanelUnifiedFont: Font {
        Font.caption.weight(.medium)
    }

    /// セット番号列（Dynamic Type・ラウンド数字）
    static var setIndexLabelFont: Font {
        Font.system(.footnote, design: .rounded).weight(.medium)
    }

    /// 重量の主数字（閲覧）
    static var weightDisplayPrimaryFont: Font {
        Font.system(.title3, design: .rounded).weight(.bold)
    }

    /// 重量の単位（数字の下に置く）
    static var weightUnitSubscriptFont: Font {
        Font.caption2.weight(.bold)
    }

    /// 回数（重量より一段弱く）
    static var repsDisplayPrimaryFont: Font {
        Font.system(.body, design: .rounded).weight(.semibold)
    }

    /// チップ・タグのラベル
    static var chipLabelFont: Font {
        Font.caption.weight(.medium)
    }

    /// 記録画面セット行の入力数字
    static var setInputNumericFont: Font {
        Font.system(.title3, design: .rounded).weight(.semibold)
    }

    /// MEMO グリッドの重量・回数（読みやすさと密度のバランス）
    static var memoStrengthNumericInputFont: Font {
        Font.system(.body, design: .rounded).weight(.semibold)
    }

    // MARK: - セット表レイアウト（閲覧・記録で共通）

    /// セット番号列（番号は subheadline 相当・入力より一段小さめ）
    static let setTableSetColumnWidth: CGFloat = 30
    /// MEMO 記録グリッドのセット列（見出し「セット」を1行で収める）
    static let memoSetIndexColumnWidth: CGFloat = 40
    /// 記録カード内の表・メモ・サマリー白枠を揃える横インセット（ScrollView の `memoCardPadding` に追加）
    static let memoRecordBlockInnerPadding: CGFloat = 10
    /// 重量列（RM列撤去後の再配分でやや広め）
    static let setTableWeightColumnWidth: CGFloat = 98
    /// 回数列
    static let setTableRepsColumnWidth: CGFloat = 58
    /// トレッドミル有酸素（傾斜・速度・時間の各入力列）
    static let setTableTreadmillFieldWidth: CGFloat = 54
    /// 補助トグル列
    static let setTableAssistColumnWidth: CGFloat = 36
    /// 完了トグル列
    static let setTableDoneColumnWidth: CGFloat = 42
    /// 上コピー（1列目のみ等）
    static let memoFlowCopyColumnWidth: CGFloat = 26
    /// アイコン1つ分（…・前回コピー・削除）
    static let memoFlowIconColumnWidth: CGFloat = 30
    /// MEMO セット行の入力ブロックとアイコン列の最低高さ（行の高さを揃える）
    static let memoStrengthRowMinHeight: CGFloat = 36
    /// MEMO 風: セット番号（重量・回数入力より一段小さく）
    static var memoFlowSetIndexFont: Font {
        Font.system(.subheadline, design: .rounded).weight(.semibold)
    }
    /// セット表の列間（MEMO 寄せ）
    static let memoFlowTableColumnSpacing: CGFloat = 3
    /// コピー・…・前回・削除の合計幅（ヘッダーと行で共通）
    static var memoFlowActionClusterWidth: CGFloat {
        memoFlowCopyColumnWidth + memoFlowIconColumnWidth * 3
    }
    /// 種別列を出すときは … を省略（コピー・前回・削除のみ）
    static var memoFlowActionClusterWidthNarrow: CGFloat {
        memoFlowCopyColumnWidth + memoFlowIconColumnWidth * 2
    }
    /// セット表「種別」列（等分レイアウト前の固定幅・参照用）
    static let memoFlowTypeColumnWidth: CGFloat = 34
    /// MEMO セット表の最小幅（横スクロール用）
    static let memoSetTableMinContentWidth: CGFloat = 480
    /// 区切り線・入力下線の不透明度（ヘアライン寄せ）
    static let memoFlowHairlineOpacity: Double = 0.38
    /// セット行グリッド内の入力セル・種別メニュー枠（8pt）
    static let memoSetFieldCornerRadius: CGFloat = 8
    /// レガシー入力セルの小さめ角丸（6pt）
    static let memoSetInputCellCornerRadius: CGFloat = 6

    /// ストリークバナー・タイムライン行・完了サマリー補助ブロック向けの弱い影（E1 相当）
    static var subtlePanelShadowOpacity: Double { cardShadowOpacity * 0.4 }
    static var subtlePanelShadowRadius: CGFloat { cardShadowRadius * 0.45 }
    static var subtlePanelShadowY: CGFloat { cardShadowY * 0.45 }

    /// セッション詳細カードの横余白（ScrollView 内）
    static let sessionContentHorizontalPadding: CGFloat = 16
    /// カード内パディング（SectionCard と揃える）
    static let sessionCardInnerPadding: CGFloat = 16

    // MARK: - Elevation / シャドウ（E1=弱 / E2=標準カード・主CTA — 設計表はファイル先頭）
    /// 標準カード（SectionCard 等）— **E2**
    static let cardShadowRadius: CGFloat = 10
    static let cardShadowY: CGFloat = 3
    static let cardShadowOpacity: Double = 0.08

    /// 主 CTA（PrimaryButton）の下方向シャドウ
    static var primaryButtonShadowColor: Color { Color.black.opacity(0.14) }
    static let primaryButtonShadowRadius: CGFloat = 8
    static let primaryButtonShadowY: CGFloat = 4

    /// セカンダリ輪郭ボタンのごく弱い浮き（任意）
    static var secondaryButtonShadowColor: Color { Color.black.opacity(0.06) }
    static let secondaryButtonShadowRadius: CGFloat = 4
    static let secondaryButtonShadowY: CGFloat = 2

    // MARK: - チップ・空状態（Phase 2 — MetricChip / EmptyState 用）
    /// 可変幅ピル（MetricChip）のごく弱いシャドウ
    static var chipShadowColor: Color { Color.black.opacity(0.06) }
    static let chipShadowRadius: CGFloat = 3
    static let chipShadowY: CGFloat = 1

    /// 空状態アイコン台紙の角丸（CTA 角丸と揃える）
    static var emptyStateIconCornerRadius: CGFloat { buttonCornerRadius }

    /// タブバー下地（シェル — 記録面 L2 と同系の白／ダーク面）
    static var tabBarChromeBackground: Color { memoRecordSurface }

    /// `UITabBarAppearance` 用（`tabBarChromeBackground` と同じ動的色）
    static var tabBarBackgroundUIColor: UIColor { UIColor.systemBackground }

    // MARK: - アニメーション
    static let animationSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let animationBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let animationQuick = Animation.easeInOut(duration: 0.2)

    // MARK: - Phase 8 — Reduce Motion（`accessibilityReduceMotion` と対になる解決関数）
    /// タブ・サブタブ・軽い状態遷移。オフ時は `animationQuick` と同値。
    static func animationTabTransition(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.14) : animationQuick
    }
    /// 主／副 CTA の押下フィードバック。オフ時は `animationSpring` と同値。
    static func animationButtonPress(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.12) : animationSpring
    }
    /// オーバーレイ・PR トースト・種目リスト件数変化。オフ時は `animationQuick` と同値。
    static func animationOverlay(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.12) : animationQuick
    }
    /// PR 祝いなどのバウンス。オフ時は `animationBouncy` と同値。
    static func animationCelebration(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.2) : animationBouncy
    }
    /// オンボーディングのページドット。オフ時は `animationSpring` と同値。
    static func animationOnboardingPage(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : animationSpring
    }

    // MARK: - Form/List 統一用トークン

    static var formSectionHeaderFont: Font { Font.subheadline.weight(.semibold) }
    static var formRowFont: Font { bodyFont }
    static var formFooterFont: Font { captionFont }

    /// accent の UIColor 表現（UIKit 設定用）
    static var accentUIColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.38, green: 0.62, blue: 0.92, alpha: 1)
            } else {
                return UIColor(red: 0.29, green: 0.56, blue: 0.85, alpha: 1)
            }
        }
    }
}

// MARK: - View 拡張
extension View {
    /// Phase 3: タブ直下ルートの共通シェル — `appBackground` とナビバー下地を揃える。
    func appTabRootChrome() -> some View {
        self
            .background(AppTheme.appBackground)
            .toolbarBackground(AppTheme.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }

    func appCardStyle() -> some View {
        padding(AppTheme.spacingLG)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
            )
            .shadow(
                color: .black.opacity(AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius,
                x: 0,
                y: AppTheme.cardShadowY
            )
    }

    /// Phase 6: モーダルシートのドラッグインジケーターと角丸を統一（iOS 17+）
    func standardSheetChrome() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(AppTheme.cardCornerRadius)
    }

    /// 履歴ストリーク・タイムライン等の弱い浮き影（`subtlePanelShadow*` と同値）
    func appSubtleElevatedShadow() -> some View {
        shadow(
            color: .black.opacity(AppTheme.subtlePanelShadowOpacity),
            radius: AppTheme.subtlePanelShadowRadius,
            x: 0,
            y: AppTheme.subtlePanelShadowY
        )
    }

    /// Phase 6: ナビゲーション **中央タイトル** 向け。大きい文字サイズで2行＋軽い縮小。
    func dynamicTypeNavigationPrincipal() -> some View {
        self
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.78)
    }

    /// Phase 6: 休憩全画面のカウントダウン数字。巨大サイズでもレイアウトが破綻しにくくする。
    func dynamicTypeRestCountdown() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.45)
    }
}

/// MEMO 風: セット表・リストの横区切り（約 0.5pt）
struct MemoFlowHairlineDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(AppTheme.memoFlowHairlineOpacity))
            .frame(height: 0.5)
    }
}
