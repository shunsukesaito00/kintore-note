// File: Modules/History/SessionSharePreviewSheet.swift
// 履歴セッション詳細のテキスト共有：カードプレビュー → システム共有（成長タブの GrowthSharePreviewSheet と同型）。

import SwiftData
import SwiftUI

private struct SessionShareTextPayload: Identifiable {
    let id = UUID()
    let text: String
}

struct SessionSharePreviewSheet: View {
    let shareKind: String
    let shareText: String
    let session: WorkoutSession
    let summary: SessionSummaryDTO
    let weightUnit: String
    let modelContext: ModelContext
    let onDismiss: () -> Void

    @State private var sharePayload: SessionShareTextPayload?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.memoSectionGap) {
                    heroHeader
                    mainPreviewCard
                    tagFooter
                }
                .padding(.horizontal, AppTheme.screenHorizontalPadding)
                .padding(.vertical, AppTheme.spacingSM)
                .padding(.bottom, AppTheme.spacingLG)
            }
            .background(AppTheme.appBackground)
            .navigationTitle(String(localized: "session_share_nav_title"))
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
                    PrimaryButton(title: String(localized: "session_share_confirm")) {
                        AnalyticsEventService.log(
                            .shareCardShared(
                                kind: shareKind,
                                source: "session_detail",
                                screen: "history_detail",
                                paywallState: "premium"
                            )
                        )
                        sharePayload = SessionShareTextPayload(text: shareText)
                    }
                }
                .padding(.horizontal, AppTheme.screenHorizontalPadding)
                .padding(.top, AppTheme.spacingSM)
                .padding(.bottom, AppTheme.spacingMD)
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
                Image(systemName: heroIconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(heroTitle)
                    .font(AppTheme.title3Font)
                    .foregroundStyle(AppTheme.primaryText)
                Text(heroSubtitle)
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

    private var heroIconName: String {
        switch shareKind {
        case "pr": return "trophy.fill"
        case "monthly": return "calendar.badge.clock"
        default: return "doc.text.fill"
        }
    }

    private var heroTitle: String {
        switch shareKind {
        case "pr": return String(localized: "share_card_pr_title")
        case "monthly": return String(format: String(localized: "share_card_monthly_title_fmt"), String(monthLabelPrefix))
        default: return String(localized: "share_card_session_title")
        }
    }

    private var heroSubtitle: String {
        AppFormatters.formatDateWithWeekday(session.startedAt)
    }

    private var monthLabelPrefix: String {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: session.startedAt)) ?? session.startedAt
        return String(AppFormatters.formatDate(monthStart).prefix(7))
    }

    // MARK: - Main card

    @ViewBuilder
    private var mainPreviewCard: some View {
        switch shareKind {
        case "pr":
            prCard
        case "monthly":
            monthlyCard
        default:
            sessionCard
        }
    }

    private var sessionCard: some View {
        SectionCard(useElevatedSurface: true) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                SectionHeaderView(title: String(localized: "growth_share_preview_metrics_header"))
                HStack(spacing: AppTheme.spacingSM) {
                    if let d = summary.durationSeconds {
                        MetricChip(text: AppFormatters.formatDuration(seconds: d))
                    }
                    MetricChip(text: "\(summary.exerciseCount)\(String(localized: "unit_exercises"))")
                    MetricChip(text: "\(summary.setCount)\(String(localized: "unit_sets"))")
                    MetricChip(text: "\(AppFormatters.formatWeightNumber(summary.totalVolume))\(weightUnit)")
                }
                MemoFlowHairlineDivider()
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text(String(localized: "session_detail_total_volume_label"))
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                    }
                    Text("\(AppFormatters.formatWeightNumber(summary.totalVolume))\(weightUnit)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if summary.exerciseCount > 0 {
                    MemoFlowHairlineDivider()
                    InlineStatView(
                        label: String(localized: "session_detail_total_reps"),
                        value: "\(summary.repCount)\(String(localized: "unit_reps"))"
                    )
                }
            }
        }
    }

    private var prCard: some View {
        SectionCard(useElevatedSurface: true) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                SectionHeaderView(title: String(localized: "share_card_pr_title"))
                Text(ShareCardComposer.prCardBodyLine(session: session, weightUnit: weightUnit))
                    .font(AppTheme.bodyTypographyFont)
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var monthlyCard: some View {
        SectionCard(useElevatedSurface: true) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                SectionHeaderView(title: String(localized: "growth_share_preview_metrics_header"))
                HStack(spacing: 0) {
                    monthlyMetricColumn(
                        title: String(localized: "stats_section_workout_counts"),
                        value: monthlyWorkoutCount,
                        icon: "figure.strengthtraining.traditional"
                    )
                    Rectangle()
                        .fill(AppTheme.separator.opacity(0.35))
                        .frame(width: 1, height: 72)
                    monthlyMetricColumn(
                        title: String(localized: "growth_hero_total_volume"),
                        valueText: "\(AppFormatters.formatWeightNumber(monthlyTotalVolume))\(weightUnit)",
                        icon: "scalemass.fill"
                    )
                }
            }
        }
    }

    private func monthlyMetricColumn(title: String, value: Int, icon: String) -> some View {
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

    private func monthlyMetricColumn(title: String, valueText: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.accent.opacity(0.9))
            Text(valueText)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .multilineTextAlignment(.center)
            Text(title)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var monthlyWorkoutCount: Int {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: session.startedAt)) ?? session.startedAt
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        let stats = WorkoutStatsService(modelContext: modelContext)
        return (try? stats.workoutCount(from: monthStart, to: monthEnd)) ?? 0
    }

    private var monthlyTotalVolume: Double {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: session.startedAt)) ?? session.startedAt
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        let stats = WorkoutStatsService(modelContext: modelContext)
        return (try? stats.totalVolume(from: monthStart, to: monthEnd)) ?? 0
    }

    private var tagFooter: some View {
        Text(tagFooterText)
            .font(AppTheme.captionTypographyFont)
            .foregroundStyle(AppTheme.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppTheme.spacingXS)
    }

    private var tagFooterText: String {
        switch shareKind {
        case "pr": return String(localized: "share_card_tag_pr")
        case "monthly": return String(localized: "share_card_tag_monthly")
        default: return String(localized: "share_card_tag_replog")
        }
    }
}
