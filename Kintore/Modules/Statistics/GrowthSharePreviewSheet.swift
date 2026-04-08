// File: Modules/Statistics/GrowthSharePreviewSheet.swift
// 成長タブの共有：概要タブに近いカードレイアウトで確認してからテキスト共有。

import SwiftUI

private struct GrowthShareTextPayload: Identifiable {
    let id = UUID()
    let text: String
}

struct GrowthSharePreviewSheet: View {
    let viewModel: StatisticsViewModel
    let weightUnit: String
    let onDismiss: () -> Void

    @State private var sharePayload: GrowthShareTextPayload?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.memoSectionGap) {
                    heroHeader
                    snapshotCard
                    if let insight = viewModel.insightMessage {
                        insightBanner(message: insight, icon: viewModel.insightIcon)
                    }
                    tagFooter
                }
                .padding(.horizontal, AppTheme.spacingLG)
                .padding(.vertical, AppTheme.spacingMD)
                .padding(.bottom, AppTheme.spacingXL)
            }
            .background(AppTheme.appBackground)
            .navigationTitle(String(localized: "growth_share_preview_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_close")) {
                        onDismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: AppTheme.spacingSM) {
                    Text(String(localized: "growth_share_preview_hint"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    PrimaryButton(title: String(localized: "growth_share_button")) {
                        let text = ShareCardComposer.growthSummaryText(viewModel: viewModel, weightUnit: weightUnit)
                        sharePayload = GrowthShareTextPayload(text: text)
                    }
                }
                .padding(.horizontal, AppTheme.spacingLG)
                .padding(.top, AppTheme.spacingMD)
                .padding(.bottom, AppTheme.spacingLG)
                .background(AppTheme.appBackground.shadow(color: .black.opacity(0.06), radius: 12, y: -4))
            }
            .sheet(item: $sharePayload) { payload in
                ShareSheet(activityItems: [payload.text], onDismiss: { sharePayload = nil })
            }
        }
        .standardSheetChrome()
    }

    // MARK: - Hero

    private var heroHeader: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMD) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft.opacity(0.65))
                    .frame(width: 52, height: 52)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "share_card_growth_title"))
                    .font(AppTheme.title3Font)
                    .foregroundStyle(AppTheme.primaryText)
                Text(String(localized: "growth_share_preview_hero_subtitle"))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacingMD)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
    }

    // MARK: - Snapshot (overview 風)

    private var snapshotCard: some View {
        SectionCard {
            VStack(spacing: AppTheme.spacingMD) {
                SectionHeaderView(title: String(localized: "growth_share_preview_metrics_header"))
                HStack(spacing: 0) {
                    sessionMetricColumn(
                        title: String(localized: "growth_hero_week"),
                        value: viewModel.workoutCountWeek,
                        icon: "calendar"
                    )
                    snapshotDivider
                    sessionMetricColumn(
                        title: String(localized: "growth_hero_month"),
                        value: viewModel.workoutCountMonth,
                        icon: "calendar.badge.clock"
                    )
                }
                MemoFlowHairlineDivider()
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text(String(localized: "growth_hero_total_volume"))
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                    }
                    Text("\(AppFormatters.formatWeightNumber(viewModel.totalVolume))\(weightUnit)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                MemoFlowHairlineDivider()
                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: "flame.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(viewModel.currentStreakWeeks > 0 ? .orange : AppTheme.tertiaryText)
                    Text(String(format: String(localized: "overview_streak_weeks_fmt"), viewModel.currentStreakWeeks))
                        .font(AppTheme.bodyTypographyFont.weight(.medium))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func sessionMetricColumn(title: String, value: Int, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.accent.opacity(0.9))
            Text("\(value)")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var snapshotDivider: some View {
        Rectangle()
            .fill(AppTheme.separator.opacity(0.35))
            .frame(width: 1, height: 72)
    }

    private func insightBanner(message: String, icon: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text(message)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AppTheme.memoCardPadding)
        .background(AppTheme.accentSoft.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }

    private var tagFooter: some View {
        Text(String(localized: "share_card_tag_replog"))
            .font(AppTheme.captionTypographyFont)
            .foregroundStyle(AppTheme.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppTheme.spacingXS)
    }
}
