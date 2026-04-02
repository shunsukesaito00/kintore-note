// File: Modules/Workout/SessionSummaryHeaderView.swift
// セッション4枠サマリー（ハブ・記録画面で共通）

import SwiftUI

struct SessionSummaryHeaderView: View {
    @Bindable var viewModel: WorkoutRecordViewModel

    var body: some View {
        let loadValue = "\(Int(round(viewModel.sessionSummaryTotalVolumeKg))) kg"
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.spacingSM) {
                sessionSummaryCell(
                    title: String(localized: "workout_summary_total_exercises"),
                    value: "\(viewModel.sessionSummaryExerciseCount)"
                )
                sessionSummaryCell(
                    title: String(localized: "workout_summary_total_sets"),
                    value: "\(viewModel.sessionSummarySetCount)"
                )
                sessionSummaryCell(
                    title: String(localized: "workout_summary_total_reps"),
                    value: "\(viewModel.sessionSummaryTotalReps)"
                )
                sessionSummaryCell(
                    title: String(localized: "workout_summary_total_load"),
                    value: loadValue
                )
            }
        }
        .padding(.horizontal, AppTheme.memoRecordBlockInnerPadding)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.memoSummaryBarBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private func sessionSummaryCell(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(AppTheme.smallCaptionFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(AppTheme.sessionSummaryValueFont)
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .fill(AppTheme.memoRecordSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: AppTheme.cardStrokeWidth)
        )
    }
}
