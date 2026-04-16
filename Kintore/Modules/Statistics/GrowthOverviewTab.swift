import SwiftUI
import SwiftData
import Charts

// MARK: - Primary Chart Selector

private enum OverviewChartKind: String, CaseIterable {
    case maxWeight
    case sessions

    var label: String {
        switch self {
        case .maxWeight: return String(localized: "overview_chart_max_weight_sum")
        case .sessions:  return String(localized: "overview_chart_sessions")
        }
    }

    var icon: String {
        switch self {
        case .maxWeight: return "scalemass.fill"
        case .sessions:  return "figure.strengthtraining.traditional"
        }
    }
}

struct GrowthOverviewTab: View {
    let viewModel: StatisticsViewModel
    let weightUnit: String

    @Environment(\.modelContext) private var modelContext
    @State private var showWeeklyGoalSheet = false
    @State private var selectedChart: OverviewChartKind = .maxWeight

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionBlockSpacing) {
                snapshotCard
                if let insight = viewModel.insightMessage {
                    insightBanner(message: insight, icon: viewModel.insightIcon)
                }
                primaryChartCard
                deltaChipsRow
                if !viewModel.trainingDaysLast12Weeks.isEmpty {
                    heatmapCard
                }
                if !viewModel.monthlySessionCounts.isEmpty {
                    monthlySessionCard
                }
                recentStatsCard
            }
            .padding(.horizontal, AppTheme.screenHorizontalPaddingCompact)
            .padding(.top, AppTheme.screenEdgeTopPadding)
            .padding(.bottom, AppTheme.screenEdgeBottomPadding)
        }
        .background(AppTheme.appBackground)
        .sheet(isPresented: $showWeeklyGoalSheet) {
            WeeklyGoalEditorSheet(initialGoal: viewModel.weeklyWorkoutGoalSessions) {
                viewModel.load(modelContext: modelContext)
            }
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
    }

    // MARK: - 1. Snapshot Card

    private var snapshotCard: some View {
        SectionCard {
            VStack(spacing: AppTheme.spacingMD) {
                HStack(spacing: 0) {
                    snapshotStatColumn(
                        title: String(localized: "growth_snapshot_training_days"),
                        value: "\(viewModel.recent30DaysTrainingCount)",
                        footnote: String(localized: "growth_snapshot_training_days_hint")
                    )
                    snapshotDivider
                    snapshotStatColumn(
                        title: String(localized: "growth_snapshot_weight_week"),
                        value: AppFormatters.formatWeightNumber(viewModel.weekMaxWeightKg),
                        footnote: weightUnit
                    )
                    snapshotDivider
                    snapshotStatColumn(
                        title: String(localized: "growth_snapshot_sessions_month"),
                        value: "\(viewModel.workoutCountMonth)",
                        footnote: String(localized: "growth_month_short")
                    )
                }

                MemoFlowHairlineDivider()

                HStack(spacing: AppTheme.spacingMD) {
                    streakBadge
                    Spacer()
                    prBadge
                }

                if !viewModel.recentPRs.isEmpty {
                    MemoFlowHairlineDivider()
                    recentPRRows
                }
            }
        }
    }

    private func snapshotStatColumn(title: String, value: String, footnote: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(footnote)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.tertiaryText)
            Text(title)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var snapshotDivider: some View {
        Rectangle()
            .fill(AppTheme.separator.opacity(0.3))
            .frame(width: 1, height: 50)
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(viewModel.currentStreakWeeks > 0 ? .orange : AppTheme.tertiaryText)
            Text(String(format: String(localized: "overview_streak_weeks_fmt"), viewModel.currentStreakWeeks))
                .font(AppTheme.captionTypographyFont.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private var prBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text(String(format: String(localized: "overview_pr_week_fmt"), viewModel.prAchievedWeek))
                .font(AppTheme.captionTypographyFont.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private var recentPRRows: some View {
        VStack(spacing: 6) {
            ForEach(viewModel.recentPRs.prefix(2), id: \.0.id) { pr, name in
                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.accent)
                    Text(name)
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Spacer()
                    Text("\(AppFormatters.formatWeightNumber(pr.weight))\(weightUnit)×\(pr.reps)")
                        .font(AppTheme.captionTypographyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }

    // MARK: - Insight Banner

    private func insightBanner(message: String, icon: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text(message)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(AppTheme.memoCardPadding)
        .background(AppTheme.accentSoft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }

    // MARK: - 2. Primary Chart

    private var primaryChartCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                chartKindPicker

                switch selectedChart {
                case .maxWeight:
                    maxWeightTrendChart
                case .sessions:
                    sessionBarChart
                }
            }
        }
    }

    private var chartKindPicker: some View {
        HStack(spacing: 0) {
            ForEach(OverviewChartKind.allCases, id: \.self) { kind in
                let isSelected = selectedChart == kind
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedChart = kind
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: kind.icon)
                            .font(.caption2)
                        Text(kind.label)
                            .font(AppTheme.captionTypographyFont)
                    }
                    .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? AppTheme.accent : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(AppTheme.inputFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius + 3))
    }

    @ViewBuilder
    private var maxWeightTrendChart: some View {
        if !viewModel.weeklyTotalMaxWeightKg.isEmpty {
            Chart {
                ForEach(viewModel.weeklyTotalMaxWeightKg, id: \.weekStart) { item in
                    AreaMark(x: .value("Week", item.weekStart), y: .value("Kg", item.totalKg))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(ModernChartStyle.lineAreaGradient(for: AppTheme.accent))
                    LineMark(x: .value("Week", item.weekStart), y: .value("Kg", item.totalKg))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.accent)
                        .lineStyle(ModernChartStyle.lineStroke())
                    PointMark(x: .value("Week", item.weekStart), y: .value("Kg", item.totalKg))
                        .foregroundStyle(AppTheme.accent)
                        .symbolSize(18)
                }
            }
            .chartYAxisLabel(weightUnit)
            .modernChartWeekDateAxes(yAxisDesiredCount: 4)
            .frame(height: AppTheme.statisticsChartHeightStandard)
        } else {
            chartEmptyState
        }
    }

    @ViewBuilder
    private var sessionBarChart: some View {
        if !viewModel.weeklySessionCounts.isEmpty {
            Chart {
                ForEach(Array(viewModel.weeklySessionCounts.prefix(viewModel.chartWeekCount)), id: \.weekStart) { item in
                    BarMark(x: .value("Week", item.weekStart), y: .value("Sessions", item.count))
                        .foregroundStyle(AppTheme.accentGradient)
                        .cornerRadius(4)
                }
            }
            .modernChartWeekDateAxes(dateDesiredCount: 6, yAxisDesiredCount: 3)
            .frame(height: AppTheme.statisticsChartHeightStandard)
        } else {
            chartEmptyState
        }
    }

    private var chartEmptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(AppTheme.tertiaryText)
                Text(String(localized: "growth_exercise_empty_period"))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.vertical, AppTheme.spacingLG)
            Spacer()
        }
    }

    // MARK: - 3. Delta Chips

    private var deltaChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                overviewDeltaChip(
                    label: String(localized: "growth_delta_sessions_week"),
                    isPositive: viewModel.weekSessionDelta >= 0,
                    formatted: "\(viewModel.weekSessionDelta > 0 ? "+" : "")\(viewModel.weekSessionDelta)"
                )
                overviewDeltaChip(
                    label: String(localized: "growth_delta_weight_week"),
                    isPositive: viewModel.weekMaxWeightDelta >= 0,
                    formatted: "\(viewModel.weekMaxWeightDelta >= 0 ? "+" : "")\(AppFormatters.formatWeightNumber(viewModel.weekMaxWeightDelta))\(weightUnit)"
                )
                overviewDeltaChip(
                    label: String(localized: "growth_delta_sessions_month"),
                    isPositive: viewModel.monthSessionDelta >= 0,
                    formatted: "\(viewModel.monthSessionDelta >= 0 ? "+" : "")\(viewModel.monthSessionDelta)"
                )
            }
        }
    }

    private func overviewDeltaChip(label: String, isPositive: Bool, formatted: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2.weight(.bold))
            Text("\(label) \(formatted)")
                .font(AppTheme.captionTypographyFont)
        }
        .foregroundStyle(isPositive ? AppTheme.accent : AppTheme.destructive)
        .padding(.horizontal, AppTheme.spacingSM)
        .padding(.vertical, AppTheme.spacingXS)
        .background((isPositive ? AppTheme.accent : AppTheme.destructive).opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - 4. Heatmap

    private var heatmapCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_heatmap_title"))
                TrainingHeatmapView(dailyCounts: viewModel.trainingDaysLast12Weeks)
            }
        }
    }

    // MARK: - 5. Monthly Volume

    private var monthlySessionCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_overview_monthly_sessions"))
                Chart(viewModel.monthlySessionCounts, id: \.monthStart) { item in
                    BarMark(
                        x: .value("月", item.monthStart, unit: .month),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(AppTheme.accentGradient)
                    .cornerRadius(5)
                }
                .chartYAxisLabel(String(localized: "growth_chart_axis_sessions"))
                .modernChartMonthBarAxes()
                .frame(height: AppTheme.statisticsChartHeightStandard)
            }
        }
    }

    // MARK: - 6. Recent 30-day Stats (compact)

    private var recentStatsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_overview_recent_30"))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingSM) {
                    compactStat(
                        icon: "calendar",
                        value: "\(viewModel.recent30DaysTrainingCount)",
                        unit: String(localized: "unit_days"),
                        label: String(localized: "growth_overview_training_days")
                    )
                    compactStat(
                        icon: "clock",
                        value: AppFormatters.formatDuration(seconds: Int(viewModel.averageDuration)),
                        unit: "",
                        label: String(localized: "growth_overview_avg_duration")
                    )
                }
            }
        }
    }

    private func compactStat(icon: String, value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingSM)
        .background(AppTheme.inputFill.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius))
    }
}
