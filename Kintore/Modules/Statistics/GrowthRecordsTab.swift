import SwiftUI
import SwiftData
import Charts

private struct WeeklyVolumePoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let bodyPart: String
    let volume: Double
}

struct ExerciseNavLinkTarget: Hashable {
    let id: UUID
    let name: String
}

struct GrowthRecordsTab: View {
    let viewModel: StatisticsViewModel
    let weightUnit: String

    @Environment(\.modelContext) private var modelContext
    @State private var selectedBodyPart: String = "胸"
    @State private var bodyPartVM = BodyPartGrowthViewModel()
    @State private var showVolumeChart = false

    private let frequencyWeekCount: Int = 12

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.memoSectionGap) {
                globalSummarySection
                bodyPartDrilldownSection
                recordsSection
            }
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
        }
        .background(AppTheme.appBackground)
        .onAppear { loadBodyPartData() }
        .onChange(of: selectedBodyPart) { _, _ in loadBodyPartData() }
    }

    private func loadBodyPartData() {
        bodyPartVM.load(
            modelContext: modelContext,
            bodyPart: selectedBodyPart,
            weekCount: frequencyWeekCount
        )
    }

    // MARK: ==============================
    // MARK: Block 1 — Global Summary
    // MARK: ==============================

    private var globalSummarySection: some View {
        VStack(spacing: AppTheme.memoSectionGap) {
            undertrainedAlert
            weekBalanceCard
            volumeChartToggle
        }
    }

    @ViewBuilder
    private var undertrainedAlert: some View {
        if !viewModel.undertrainedBodyParts.isEmpty {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "growth_records_undertrained_title"))
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(viewModel.undertrainedBodyParts.joined(separator: "、"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer(minLength: 0)
            }
            .padding(AppTheme.memoCardPadding)
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(Color.orange.opacity(0.2), lineWidth: AppTheme.cardStrokeWidth)
            )
        }
    }

    private var weekBalanceCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_records_this_week_balance"))
                if thisWeekVolumeTotal <= 0 {
                    Text(String(localized: "growth_records_no_data"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    let maxVol = viewModel.thisWeekVolumeByPart.map(\.volume).max() ?? 1
                    ForEach(viewModel.thisWeekVolumeByPart, id: \.bodyPart) { item in
                        HStack(spacing: AppTheme.spacingSM) {
                            Text(item.bodyPart)
                                .font(AppTheme.captionTypographyFont.weight(.medium))
                                .frame(width: 40, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.inputFill)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.accentGradient)
                                        .frame(width: max(4, geo.size.width * CGFloat(item.volume / maxVol)))
                                }
                            }
                            .frame(height: 18)
                            Text(String(format: "%.0f%%", item.volume / thisWeekVolumeTotal * 100))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var volumeChartToggle: some View {
        if !viewModel.weeklyVolumeByPart.isEmpty {
            SectionCard {
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showVolumeChart.toggle()
                        }
                    } label: {
                        HStack {
                            SectionHeaderView(title: String(localized: "growth_records_weekly_volume_part"))
                            Spacer()
                            Image(systemName: showVolumeChart ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)

                    if showVolumeChart {
                        let points = viewModel.weeklyVolumeByPart.map {
                            WeeklyVolumePoint(weekStart: $0.weekStart, bodyPart: $0.bodyPart, volume: $0.volume)
                        }
                        Chart(points) { point in
                            BarMark(
                                x: .value("週", point.weekStart, unit: .weekOfYear),
                                y: .value("挙上量", point.volume)
                            )
                            .foregroundStyle(by: .value(String(localized: "chart_legend_body_part"), point.bodyPart))
                        }
                        .chartLegend(position: .bottom, spacing: 8)
                        .chartYAxisLabel(weightUnit)
                        .modernChartWeekDateAxes()
                        .frame(height: 200)
                    }
                }
            }
        }
    }

    private var thisWeekVolumeTotal: Double {
        viewModel.thisWeekVolumeByPart.map(\.volume).reduce(0, +)
    }

    // MARK: ==============================
    // MARK: Block 2 — Body Part Drilldown
    // MARK: ==============================

    private var bodyPartDrilldownSection: some View {
        VStack(spacing: AppTheme.memoSectionGap) {
            bodyPartSelector
            bodyPartDetailCard
        }
    }

    private var bodyPartSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                ForEach(WorkoutStatsService.canonicalBodyParts, id: \.self) { part in
                    let isSelected = selectedBodyPart == part
                    Button {
                        selectedBodyPart = part
                    } label: {
                        Text(part)
                            .font(AppTheme.captionTypographyFont.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? AppTheme.accent : AppTheme.inputFill)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var bodyPartDetailCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                HStack {
                    Text(selectedBodyPart)
                        .font(AppTheme.title3Font)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(String(localized: "growth_body_part_avg_per_week"))
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(String(format: "%.1f", bodyPartVM.averagePerWeek) + String(localized: "growth_body_part_times_per_week"))
                            .font(AppTheme.bodySemiboldFont)
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                if !bodyPartVM.weeklyFrequency.isEmpty {
                    Chart(bodyPartVM.weeklyFrequency, id: \.weekStart) { item in
                        BarMark(
                            x: .value("週", item.weekStart, unit: .weekOfYear),
                            y: .value("回", item.count)
                        )
                        .foregroundStyle(AppTheme.accentGradient)
                        .cornerRadius(4)
                    }
                    .modernChartWeekDateAxes(dateDesiredCount: 6, yAxisDesiredCount: 3)
                    .frame(height: 70)

                    Text(String(format: String(localized: "growth_overview_last_weeks_fmt"), frequencyWeekCount))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }

                if !bodyPartVM.exercisePRs.isEmpty {
                    MemoFlowHairlineDivider()
                        .padding(.vertical, 4)

                    Text(String(format: String(localized: "growth_body_part_pr_list_fmt"), selectedBodyPart))
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.primaryText)

                    ForEach(bodyPartVM.exercisePRs) { item in
                        NavigationLink(value: ExerciseNavLinkTarget(id: item.id, name: item.exerciseName)) {
                            prRow(item)
                        }
                        .buttonStyle(.plain)

                        if item.id != bodyPartVM.exercisePRs.last?.id {
                            MemoFlowHairlineDivider()
                        }
                    }
                } else {
                    Text(String(localized: "growth_body_part_no_exercises"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.vertical, AppTheme.spacingSM)
                }
            }
        }
    }

    private func prRow(_ item: BodyPartExercisePR) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.exerciseName)
                    .font(AppTheme.bodyTypographyFont)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                if let pr = item.pr {
                    Text("\(AppFormatters.formatWeightNumber(pr.weight))\(weightUnit) × \(pr.reps)\(String(localized: "unit_reps"))")
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.accent)
                } else if item.exerciseKind.participatesInPersonalRecord {
                    Text(String(localized: "growth_body_part_no_pr"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.tertiaryText)
                } else {
                    Text(String(localized: "growth_body_part_not_applicable"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let pr = item.pr {
                    Text(AppFormatters.formatDate(pr.achievedAt))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: ==============================
    // MARK: Block 3 — Records
    // MARK: ==============================

    private var recordsSection: some View {
        VStack(spacing: AppTheme.memoSectionGap) {
            prTimelineCard
            bodyPartTotalsCard
            exerciseListCard
        }
    }

    // MARK: - PR Timeline

    private var prTimelineCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_records_pr_timeline"))

                if viewModel.recentPRs.isEmpty {
                    Text(String(localized: "growth_records_no_pr"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.vertical, AppTheme.spacingMD)
                } else {
                    ForEach(viewModel.recentPRs.prefix(10), id: \.0.id) { pr, name in
                        HStack(spacing: AppTheme.spacingSM) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentSoft)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(name)
                                    .font(AppTheme.bodyTypographyFont)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .lineLimit(1)
                                Text("\(AppFormatters.formatWeightNumber(pr.weight))\(weightUnit) × \(pr.reps)\(String(localized: "unit_reps"))")
                                    .font(AppTheme.bodySemiboldFont)
                                    .foregroundStyle(AppTheme.accent)
                            }

                            Spacer()

                            Text(AppFormatters.formatDate(pr.achievedAt))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                        .padding(.vertical, 2)

                        if pr.id != viewModel.recentPRs.prefix(10).last?.0.id {
                            MemoFlowHairlineDivider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Body Part Totals

    private var bodyPartTotalsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_records_body_part_totals"))

                if bodyPartDetailRows.isEmpty {
                    Text(String(localized: "growth_records_no_data"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    HStack {
                        Text(String(localized: "growth_col_part"))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.tertiaryText)
                            .frame(width: 36, alignment: .leading)
                        Spacer()
                        Text(String(localized: "growth_col_volume"))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.tertiaryText)
                            .frame(width: 72, alignment: .trailing)
                        Text(String(localized: "growth_col_sets"))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.tertiaryText)
                            .frame(width: 36, alignment: .trailing)
                        Text(String(localized: "growth_col_reps"))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.tertiaryText)
                            .frame(width: 40, alignment: .trailing)
                    }

                    ForEach(bodyPartDetailRows, id: \.part) { row in
                        HStack(alignment: .firstTextBaseline) {
                            Text(row.part)
                                .font(AppTheme.captionTypographyFont.weight(.medium))
                                .frame(width: 36, alignment: .leading)
                            Spacer()
                            Text(AppFormatters.formatWeightNumber(row.volume) + weightUnit)
                                .font(AppTheme.bodySemiboldFont)
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 72, alignment: .trailing)
                            Text("\(row.sets)")
                                .font(AppTheme.captionTypographyFont)
                                .frame(width: 36, alignment: .trailing)
                            Text("\(row.reps)")
                                .font(AppTheme.captionTypographyFont)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
        }
    }

    private var bodyPartDetailRows: [(part: String, volume: Double, sets: Int, reps: Int)] {
        let v = Dictionary(uniqueKeysWithValues: viewModel.bodyPartVolumes.map { ($0.bodyPart, $0.volume) })
        let s = Dictionary(uniqueKeysWithValues: viewModel.bodyPartSetCounts.map { ($0.bodyPart, $0.count) })
        let r = Dictionary(uniqueKeysWithValues: viewModel.bodyPartRepCounts.map { ($0.bodyPart, $0.reps) })
        let keys = Set(v.keys).union(s.keys).union(r.keys)
        return keys.map { part -> (part: String, volume: Double, sets: Int, reps: Int) in
            (part: part, volume: v[part] ?? 0, sets: s[part] ?? 0, reps: r[part] ?? 0)
        }.sorted { $0.volume > $1.volume }
    }

    // MARK: - Exercise List

    private var exerciseListCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "growth_records_exercise_list"))

                if viewModel.allExercises.isEmpty {
                    Text(String(localized: "growth_records_no_exercises"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(viewModel.allExercises, id: \.id) { ex in
                        NavigationLink(value: ExerciseNavLinkTarget(id: ex.id, name: ex.name)) {
                            HStack {
                                Text(ex.name)
                                    .font(AppTheme.bodyTypographyFont)
                                    .foregroundStyle(AppTheme.primaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.tertiaryText)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)

                        if ex.id != viewModel.allExercises.last?.id {
                            MemoFlowHairlineDivider()
                        }
                    }
                }
            }
        }
    }

}
