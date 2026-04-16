import SwiftUI
import SwiftData

/// 記録タブ: 今月の部位バランス・月平均回数
struct GrowthRecordsTab: View {
    let viewModel: StatisticsViewModel
    let weightUnit: String

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionBlockSpacing) {
                monthPartBalanceSection
                monthAvgRepsPartSection
                monthAvgRepsExerciseSection
            }
            .padding(.horizontal, AppTheme.screenHorizontalPaddingCompact)
            .padding(.top, AppTheme.screenEdgeTopPadding)
            .padding(.bottom, AppTheme.screenEdgeBottomPadding)
        }
        .background(AppTheme.appBackground)
    }

    private var monthPartBalanceSection: some View {
        SectionCard(density: .dense) {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_records_month_part_balance"))
                let items = viewModel.currentMonthVolumeByBodyPart
                let total = items.map(\.volume).reduce(0, +)
                if total <= 0 {
                    Text(String(localized: "growth_records_no_data"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    let maxV = items.map(\.volume).max() ?? 1
                    ForEach(items, id: \.bodyPart) { item in
                        HStack(spacing: AppTheme.spacingSM) {
                            Text(item.bodyPart)
                                .font(AppTheme.captionTypographyFont.weight(.medium))
                                .frame(width: 44, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.inputFill)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.accentGradient)
                                        .frame(width: max(4, geo.size.width * CGFloat(item.volume / maxV)))
                                }
                            }
                            .frame(height: 18)
                            Text(String(format: "%.0f%%", item.volume / total * 100))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private var monthAvgRepsPartSection: some View {
        SectionCard(density: .dense) {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_records_month_avg_reps_part"))
                let rows = viewModel.currentMonthAvgRepsPerDayByBodyPart
                if rows.isEmpty {
                    Text(String(localized: "growth_records_no_data"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(rows, id: \.bodyPart) { row in
                        HStack {
                            Text(row.bodyPart)
                                .font(AppTheme.bodyTypographyFont)
                            Spacer()
                            Text(String(format: "%.1f", row.average))
                                .font(AppTheme.numericEmphasisFont)
                                .foregroundStyle(AppTheme.accent)
                            Text(String(localized: "growth_records_reps_per_day_unit"))
                                .font(AppTheme.captionTypographyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var monthAvgRepsExerciseSection: some View {
        SectionCard(density: .dense) {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_records_month_avg_reps_exercise"))
                let rows = viewModel.currentMonthAvgRepsPerDayByExercise
                if rows.isEmpty {
                    Text(String(localized: "growth_records_no_data"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(rows, id: \.exerciseId) { row in
                        NavigationLink(value: ExerciseNavLinkTarget(id: row.exerciseId, name: row.name)) {
                            HStack {
                                Text(row.name)
                                    .font(AppTheme.bodyTypographyFont)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.1f", row.average))
                                    .font(AppTheme.numericEmphasisFont)
                                    .foregroundStyle(AppTheme.accent)
                                Text(String(localized: "growth_records_reps_per_day_unit"))
                                    .font(AppTheme.captionTypographyFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}
