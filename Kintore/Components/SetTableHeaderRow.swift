// File: Components/SetTableHeaderRow.swift
// セット表の列見出し（セッション詳細・記録で共通）

import SwiftUI

struct SetTableHeaderRow: View {
    let exerciseKind: ExerciseKind
    let weightUnit: String
    /// MEMO 風: 「重さ」「回数」ラベル（単位は行の下付きで表示）
    var memoStyleHeaders: Bool = false
    /// `Exercise.cardioInputStyle`（トレッドミル有酸素の3列見出し用）
    var cardioInputStyle: String? = nil
    /// MEMO 筋力: 種別を専用列で出す（`SetRowView` と列幅を揃える）
    var showSetMetaColumns: Bool = false
    /// アクション列幅（種別列があるときは狭い版）
    var memoActionClusterWidth: CGFloat = AppTheme.memoFlowActionClusterWidth

    private var isMemoStrengthGrid: Bool {
        memoStyleHeaders && (exerciseKind == .strength || exerciseKind == .weightedBodyweight)
    }

    private var isMemoTreadmillCardio: Bool {
        memoStyleHeaders && exerciseKind == .cardio && cardioInputStyle == CardioInputStyle.treadmill.rawValue
    }

    var body: some View {
        if isMemoStrengthGrid {
            memoStrengthHeader
        } else if isMemoTreadmillCardio {
            memoTreadmillCardioHeader
        } else {
            legacyHeader
        }
    }

    private var memoTreadmillCardioHeader: some View {
        HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
            Text(String(localized: "set_header_set"))
                .font(AppTheme.memoSetTableHeaderFont)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .frame(width: AppTheme.memoSetIndexColumnWidth, alignment: .center)
            HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
                Text(String(localized: "set_header_incline"))
                    .font(AppTheme.memoSetTableHeaderFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
                Text(String(localized: "set_header_speed"))
                    .font(AppTheme.memoSetTableHeaderFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
                Text(String(localized: "set_header_seconds"))
                    .font(AppTheme.memoSetTableHeaderFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            Color.clear
                .frame(width: memoActionClusterWidth, height: AppTheme.memoStrengthRowMinHeight)
            Text(String(localized: "set_header_assist"))
                .font(AppTheme.memoSetTableHeaderFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(width: AppTheme.setTableAssistColumnWidth, height: AppTheme.memoStrengthRowMinHeight, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: AppTheme.memoStrengthRowMinHeight)
    }

    private var memoStrengthHeader: some View {
        HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
            Text(String(localized: "set_header_set"))
                .font(AppTheme.memoSetTableHeaderFont)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .frame(width: AppTheme.memoSetIndexColumnWidth, alignment: .center)
            HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
                Text(column1Title)
                    .font(AppTheme.memoSetTableHeaderFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(column2Title)
                    .font(AppTheme.memoSetTableHeaderFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                if showSetMetaColumns {
                    Text(String(localized: "set_header_set_type"))
                        .font(AppTheme.memoSetTableHeaderFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            Color.clear
                .frame(width: memoActionClusterWidth, height: AppTheme.memoStrengthRowMinHeight)
            Text(String(localized: "set_header_assist"))
                .font(AppTheme.memoSetTableHeaderFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(width: AppTheme.setTableAssistColumnWidth, height: AppTheme.memoStrengthRowMinHeight, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: AppTheme.memoStrengthRowMinHeight)
    }

    private var legacyHeader: some View {
        HStack(alignment: .bottom, spacing: AppTheme.spacingMD) {
            Text(String(localized: "set_header_set"))
                .font(AppTheme.tableHeaderLabelFont)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: AppTheme.setTableSetColumnWidth, alignment: .leading)
            if exerciseKind == .cardio, cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                Text(String(localized: "set_header_incline"))
                    .font(AppTheme.tableHeaderLabelFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: AppTheme.setTableTreadmillFieldWidth, alignment: .center)
                Text(String(localized: "set_header_speed"))
                    .font(AppTheme.tableHeaderLabelFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: AppTheme.setTableTreadmillFieldWidth, alignment: .center)
                Text(String(localized: "set_header_seconds"))
                    .font(AppTheme.tableHeaderLabelFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: AppTheme.setTableTreadmillFieldWidth, alignment: .center)
            } else {
                Text(column1Title)
                    .font(AppTheme.tableHeaderLabelFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: AppTheme.setTableWeightColumnWidth, alignment: .center)
                Text(column2Title)
                    .font(AppTheme.tableHeaderLabelFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: AppTheme.setTableRepsColumnWidth, alignment: .center)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, memoStyleHeaders ? 2 : AppTheme.spacingXS)
        .padding(.bottom, memoStyleHeaders ? 1 : 2)
    }

    private var column1Title: String {
        if memoStyleHeaders {
            switch exerciseKind {
            case .strength, .weightedBodyweight: return String(localized: "set_header_weight")
            case .time: return String(localized: "set_header_seconds")
            case .cardio: return String(localized: "set_header_distance")
            }
        }
        switch exerciseKind {
        case .strength, .weightedBodyweight:
            return String(localized: "set_header_weight")
        case .time: return String(localized: "set_header_seconds")
        case .cardio: return String(localized: "unit_km")
        }
    }

    private var column2Title: String {
        if memoStyleHeaders {
            switch exerciseKind {
            case .strength, .weightedBodyweight: return String(localized: "set_header_reps")
            case .time: return ""
            case .cardio: return String(localized: "set_header_seconds")
            }
        }
        switch exerciseKind {
        case .strength, .weightedBodyweight:
            return String(localized: "set_header_reps")
        case .time: return ""
        case .cardio: return String(localized: "set_header_seconds")
        }
    }
}

#Preview {
    VStack {
        SetTableHeaderRow(exerciseKind: .strength, weightUnit: "kg")
        SetTableHeaderRow(exerciseKind: .strength, weightUnit: "kg", memoStyleHeaders: true)
        SetTableHeaderRow(exerciseKind: .time, weightUnit: "kg")
        SetTableHeaderRow(exerciseKind: .cardio, weightUnit: "kg")
    }
    .padding()
}
