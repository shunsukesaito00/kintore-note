import SwiftUI
import SwiftData
import Charts

private struct ChartDataPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let maxWeight: Double
    let volume: Double
    let totalReps: Int
    let estimated1RM: Double?
    let sessionTotalDurationSeconds: Int
    let sessionMaxDurationSeconds: Int
    let sessionTotalDistanceMeters: Double
    let sessionTotalCardioDurationSeconds: Int
    let sessionMaxDistanceMeters: Double
}

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ExerciseDetailView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext
    let exerciseId: UUID
    let exerciseName: String

    @State private var viewModel = ExerciseDetailViewModel()
    @State private var selectedPeriod: ExerciseTrendPeriod = .oneMonth
    @State private var chartSelectedDate: Date?
    @State private var allExercises: [Exercise] = []
    @State private var currentExerciseId: UUID?
    @State private var currentExerciseName: String = ""
    @State private var showPremiumSheet = false
    @State private var exportFileURL: URL?
    private let premium = PremiumService.shared

    private var freePeriods: [ExerciseTrendPeriod] { [.oneMonth, .threeMonths] }

    private var periodStart: Date? { selectedPeriod.startDate() }

    private var filteredHistory: [(WorkoutExercise, WorkoutSession)] {
        guard let start = periodStart else { return viewModel.history }
        return viewModel.history.filter { ($0.1.endedAt ?? $0.1.startedAt) >= start }
    }

    private var chartData: [ChartDataPoint] {
        viewModel.trendPoints.map {
            ChartDataPoint(
                date: $0.date,
                maxWeight: $0.maxWeight,
                volume: $0.totalVolume,
                totalReps: $0.totalReps,
                estimated1RM: $0.estimated1RM,
                sessionTotalDurationSeconds: $0.sessionTotalDurationSeconds,
                sessionMaxDurationSeconds: $0.sessionMaxDurationSeconds,
                sessionTotalDistanceMeters: $0.sessionTotalDistanceMeters,
                sessionTotalCardioDurationSeconds: $0.sessionTotalCardioDurationSeconds,
                sessionMaxDistanceMeters: $0.sessionMaxDistanceMeters
            )
        }
    }

    var body: some View {
        Group {
            if let err = viewModel.loadError {
                VStack(spacing: AppTheme.spacingMD) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(AppTheme.destructive)
                    Text(err)
                        .font(AppTheme.bodyTypographyFont)
                        .foregroundStyle(AppTheme.destructive)
                        .multilineTextAlignment(.center)
                    Button(String(localized: "common_retry")) { load() }
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.accent)
                }
                .padding()
            } else {
                detailContent
            }
        }
        .navigationTitle(currentExerciseName.isEmpty ? exerciseName : currentExerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if premium.isPremium {
                    Button {
                        exportExerciseCSV()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(String(localized: "export_csv_exercise_period"))
                } else {
                    Button {
                        showPremiumSheet = true
                    } label: {
                        Image(systemName: "lock.square.stack")
                    }
                    .accessibilityLabel(String(localized: "export_csv_exercise_period"))
                }
            }
        }
        .background(AppTheme.appBackground)
        .onAppear {
            if currentExerciseId == nil {
                currentExerciseId = exerciseId
                currentExerciseName = exerciseName
            }
            loadAllExercises()
            load()
        }
        .onChange(of: premium.isPremium) { _, isPremium in
            if !isPremium && !freePeriods.contains(selectedPeriod) {
                selectedPeriod = .oneMonth
            }
            load()
        }
        .onChange(of: selectedPeriod) { _, _ in load() }
        .sheet(isPresented: $showPremiumSheet) {
            NavigationStack { PremiumCTAView(analyticsSource: "exercise_detail") }
                .standardSheetChrome()
        }
        .sheet(item: Binding(
            get: { exportFileURL.map { IdentifiableURL(url: $0) } },
            set: { exportFileURL = $0?.url }
        )) { identifiable in
            ShareSheet(activityItems: [identifiable.url], onDismiss: { exportFileURL = nil })
        }
    }

    // MARK: - Main Content

    private var detailContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.memoSectionGap) {
                if allExercises.count > 1 { exerciseSwitcherCard }
                if viewModel.exerciseKind.participatesInPersonalRecord, let pr = viewModel.pr { prCard(pr) }
                periodPickerCard
                if !chartData.isEmpty {
                    exerciseChartsSection
                }
                if !viewModel.trendPoints.isEmpty {
                    comparisonSection
                    nextSessionInsightCard
                }
                kpiSection
                if !viewModel.prMilestones.isEmpty {
                    prMilestoneHistorySection
                }
                historyCard
            }
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
        }
    }

    @ViewBuilder
    private var exerciseChartsSection: some View {
        switch viewModel.exerciseKind {
        case .strength, .weightedBodyweight:
            maxWeightChartCard
            if currentExerciseUsesWeight {
                e1rmChartCard
            }
            volumeChartCard
            repsChartCard
        case .time:
            timeSessionTotalDurationChart
            timeBestSetDurationChart
        case .cardio:
            cardioSessionDistanceChart
            cardioSessionDurationChart
        }
    }

    // MARK: - Exercise Switcher

    private var exerciseSwitcherCard: some View {
        SectionCard {
            Picker(String(localized: "exercise_detail_switch"), selection: Binding(
                get: { currentExerciseId ?? exerciseId },
                set: { newId in
                    currentExerciseId = newId
                    currentExerciseName = allExercises.first(where: { $0.id == newId })?.name ?? exerciseName
                    chartSelectedDate = nil
                    load()
                }
            )) {
                ForEach(allExercises, id: \.id) { ex in
                    Text(ex.name).tag(ex.id)
                }
            }
            .pickerStyle(.menu)
            .font(AppTheme.bodySemiboldFont)
        }
    }

    // MARK: - PR Card

    private func prCard(_ pr: PersonalRecord) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_current_best"))
                HStack {
                    Text("\(AppFormatters.formatWeight(pr.weight)) × \(pr.reps)\(String(localized: "unit_reps"))")
                        .font(AppTheme.bodySemiboldFont)
                    Spacer()
                    Text(AppFormatters.formatDateWithWeekday(pr.achievedAt))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Text(String(localized: "exercise_detail_pr_explanation"))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
    }

    // MARK: - Period Picker

    private var periodPickerCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_period"))
                HStack(spacing: 0) {
                    ForEach(ExerciseTrendPeriod.allCases, id: \.self) { period in
                        let isLocked = !premium.isPremium && !freePeriods.contains(period)
                        let isSelected = selectedPeriod == period
                        Button {
                            if isLocked {
                                showPremiumSheet = true
                            } else {
                                selectedPeriod = period
                            }
                        } label: {
                            HStack(spacing: 3) {
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2)
                                }
                                Text(period.displayName)
                                    .font(AppTheme.captionTypographyFont)
                            }
                            .foregroundStyle(isSelected ? .white : (isLocked ? AppTheme.tertiaryText : AppTheme.secondaryText))
                            .padding(.horizontal, 10)
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
        }
    }

    // MARK: - Charts

    private var maxWeightChartCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_max_weight_trend"))
                Chart {
                    ForEach(chartData) { point in
                        AreaMark(x: .value("日付", point.date), y: .value("重量", point.maxWeight))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(ModernChartStyle.lineAreaGradient(for: AppTheme.accent))
                    }
                    ForEach(chartData) { point in
                        LineMark(x: .value("日付", point.date), y: .value("重量", point.maxWeight))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.accent)
                            .lineStyle(ModernChartStyle.lineStroke())
                        PointMark(x: .value("日付", point.date), y: .value("重量", point.maxWeight))
                            .foregroundStyle(AppTheme.accent)
                            .symbolSize(28)
                    }
                    if let pr = viewModel.pr, periodStart == nil || pr.achievedAt >= (periodStart ?? .distantPast) {
                        RuleMark(x: .value(String(localized: "chart_pr_marker"), pr.achievedAt))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(AppTheme.accent.opacity(0.8))
                            .annotation(position: .top, alignment: .center) {
                                Text(String(localized: "chart_pr_marker")).font(.caption2.weight(.medium)).foregroundStyle(AppTheme.accent)
                            }
                    }
                    if let selected = chartSelectedDate, let match = closestChartPoint(to: selected) {
                        RuleMark(x: .value("選択", match.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(AppTheme.secondaryText)
                            .annotation(position: .top, alignment: .center) {
                                ChartAnnotationBubble(date: match.date, label: String(localized: "chart_label_weight"), value: "\(AppFormatters.formatWeightNumber(match.maxWeight))\(weightUnit)")
                            }
                    }
                }
                .chartYAxisLabel(weightUnit)
                .chartXSelection(value: $chartSelectedDate)
                .modernChartDateValueAxes()
                .frame(height: 200)
            }
        }
    }

    private var volumeChartCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_volume_trend"))
                Chart {
                    ForEach(chartData) { point in
                        BarMark(x: .value("日付", point.date), y: .value("挙上量", point.volume))
                            .foregroundStyle(AppTheme.accent.gradient)
                            .cornerRadius(4)
                    }
                    if let selected = chartSelectedDate, let match = closestChartPoint(to: selected) {
                        RuleMark(x: .value("選択", match.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(AppTheme.secondaryText)
                            .annotation(position: .top, alignment: .center) {
                                ChartAnnotationBubble(date: match.date, label: String(localized: "chart_label_volume"), value: "\(AppFormatters.formatWeightNumber(match.volume))\(weightUnit)")
                            }
                    }
                }
                .chartYAxisLabel(weightUnit)
                .chartXSelection(value: $chartSelectedDate)
                .modernChartDateValueAxes()
                .frame(height: 160)
            }
        }
    }

    private var repsChartCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_reps_trend"))
                Chart {
                    ForEach(chartData) { point in
                        AreaMark(x: .value("日付", point.date), y: .value("レップ", point.totalReps))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(ModernChartStyle.lineAreaGradient(for: AppTheme.accentSecondary))
                    }
                    ForEach(chartData) { point in
                        LineMark(x: .value("日付", point.date), y: .value("レップ", point.totalReps))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.accentSecondary)
                            .lineStyle(ModernChartStyle.lineStroke())
                        PointMark(x: .value("日付", point.date), y: .value("レップ", point.totalReps))
                            .foregroundStyle(AppTheme.accentSecondary)
                            .symbolSize(22)
                    }
                    if let selected = chartSelectedDate, let match = closestChartPoint(to: selected) {
                        RuleMark(x: .value("選択", match.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(AppTheme.secondaryText)
                            .annotation(position: .top, alignment: .center) {
                                ChartAnnotationBubble(date: match.date, label: String(localized: "chart_label_reps"), value: "\(match.totalReps)\(String(localized: "unit_reps"))")
                            }
                    }
                }
                .chartYAxisLabel(String(localized: "unit_reps"))
                .chartXSelection(value: $chartSelectedDate)
                .modernChartDateValueAxes()
                .frame(height: 140)
            }
        }
    }

    // MARK: - Charts (時間・有酸素)

    private var timeSessionTotalDurationChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_chart_session_total_time"))
                Chart {
                    ForEach(chartData) { point in
                        BarMark(x: .value("日付", point.date), y: .value("秒", point.sessionTotalDurationSeconds))
                            .foregroundStyle(AppTheme.accent.gradient)
                            .cornerRadius(4)
                    }
                    if let selected = chartSelectedDate, let match = closestChartPoint(to: selected) {
                        RuleMark(x: .value("選択", match.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(AppTheme.secondaryText)
                            .annotation(position: .top, alignment: .center) {
                                ChartAnnotationBubble(date: match.date, label: String(localized: "exercise_detail_chart_session_total_time"), value: "\(match.sessionTotalDurationSeconds)\(String(localized: "unit_seconds"))")
                            }
                    }
                }
                .chartYAxisLabel(String(localized: "unit_seconds"))
                .chartXSelection(value: $chartSelectedDate)
                .modernChartDateValueAxes()
                .frame(height: 160)
            }
        }
    }

    private var timeBestSetDurationChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_chart_best_set_duration"))
                Chart {
                    ForEach(chartData) { point in
                        AreaMark(x: .value("日付", point.date), y: .value("秒", point.sessionMaxDurationSeconds))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(ModernChartStyle.lineAreaGradient(for: AppTheme.accent))
                    }
                    ForEach(chartData) { point in
                        LineMark(x: .value("日付", point.date), y: .value("秒", point.sessionMaxDurationSeconds))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.accent)
                            .lineStyle(ModernChartStyle.lineStroke())
                        PointMark(x: .value("日付", point.date), y: .value("秒", point.sessionMaxDurationSeconds))
                            .foregroundStyle(AppTheme.accent)
                            .symbolSize(26)
                    }
                    if let selected = chartSelectedDate, let match = closestChartPoint(to: selected) {
                        RuleMark(x: .value("選択", match.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(AppTheme.secondaryText)
                            .annotation(position: .top, alignment: .center) {
                                ChartAnnotationBubble(date: match.date, label: String(localized: "exercise_detail_chart_best_set_duration"), value: "\(match.sessionMaxDurationSeconds)\(String(localized: "unit_seconds"))")
                            }
                    }
                }
                .chartYAxisLabel(String(localized: "unit_seconds"))
                .chartXSelection(value: $chartSelectedDate)
                .modernChartDateValueAxes()
                .frame(height: 160)
            }
        }
    }

    private var cardioSessionDistanceChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_chart_session_distance"))
                Chart {
                    ForEach(chartData) { point in
                        BarMark(x: .value("日付", point.date), y: .value("km", point.sessionTotalDistanceMeters / 1000))
                            .foregroundStyle(AppTheme.accent.gradient)
                            .cornerRadius(4)
                    }
                    if let selected = chartSelectedDate, let match = closestChartPoint(to: selected) {
                        RuleMark(x: .value("選択", match.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(AppTheme.secondaryText)
                            .annotation(position: .top, alignment: .center) {
                                ChartAnnotationBubble(date: match.date, label: String(localized: "exercise_detail_chart_session_distance"), value: "\(AppFormatters.formatWeightNumber(match.sessionTotalDistanceMeters / 1000))\(String(localized: "unit_km"))")
                            }
                    }
                }
                .chartYAxisLabel(String(localized: "unit_km"))
                .chartXSelection(value: $chartSelectedDate)
                .modernChartDateValueAxes()
                .frame(height: 160)
            }
        }
    }

    private var cardioSessionDurationChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_chart_session_cardio_duration"))
                Chart {
                    ForEach(chartData) { point in
                        AreaMark(x: .value("日付", point.date), y: .value("秒", point.sessionTotalCardioDurationSeconds))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(ModernChartStyle.lineAreaGradient(for: AppTheme.accentSecondary))
                    }
                    ForEach(chartData) { point in
                        LineMark(x: .value("日付", point.date), y: .value("秒", point.sessionTotalCardioDurationSeconds))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.accentSecondary)
                            .lineStyle(ModernChartStyle.lineStroke())
                        PointMark(x: .value("日付", point.date), y: .value("秒", point.sessionTotalCardioDurationSeconds))
                            .foregroundStyle(AppTheme.accentSecondary)
                            .symbolSize(22)
                    }
                    if let selected = chartSelectedDate, let match = closestChartPoint(to: selected) {
                        RuleMark(x: .value("選択", match.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(AppTheme.secondaryText)
                            .annotation(position: .top, alignment: .center) {
                                ChartAnnotationBubble(date: match.date, label: String(localized: "exercise_detail_chart_session_cardio_duration"), value: "\(match.sessionTotalCardioDurationSeconds)\(String(localized: "unit_seconds"))")
                            }
                    }
                }
                .chartYAxisLabel(String(localized: "unit_seconds"))
                .chartXSelection(value: $chartSelectedDate)
                .modernChartDateValueAxes()
                .frame(height: 140)
            }
        }
    }

    // MARK: - Estimated 1RM

    private var currentExerciseUsesWeight: Bool {
        guard let exId = currentExerciseId,
              let ex = allExercises.first(where: { $0.id == exId }) else { return true }
        return ExerciseKind(stored: ex.exerciseKind).usesLoadVolume
    }

    private var e1rmChartCard: some View {
        let e1rmData = chartData.filter { $0.estimated1RM != nil }
        return Group {
            if !e1rmData.isEmpty {
                SectionCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                        SectionHeaderView(title: String(localized: "growth_e1rm_title"))
                        Chart {
                            ForEach(e1rmData) { point in
                                AreaMark(
                                    x: .value("日付", point.date),
                                    y: .value("e1RM", point.estimated1RM ?? 0)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(ModernChartStyle.lineAreaGradient(for: AppTheme.accentSecondary))
                            }
                            ForEach(e1rmData) { point in
                                LineMark(
                                    x: .value("日付", point.date),
                                    y: .value("e1RM", point.estimated1RM ?? 0)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(AppTheme.accentSecondary)
                                .lineStyle(ModernChartStyle.lineStroke())
                                PointMark(
                                    x: .value("日付", point.date),
                                    y: .value("e1RM", point.estimated1RM ?? 0)
                                )
                                .foregroundStyle(AppTheme.accentSecondary)
                                .symbolSize(22)
                            }
                            if let selected = chartSelectedDate, let match = closestChartPoint(to: selected),
                               let e1rm = match.estimated1RM {
                                RuleMark(x: .value("選択", match.date))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .annotation(position: .top, alignment: .center) {
                                        ChartAnnotationBubble(date: match.date, label: String(localized: "growth_e1rm_title"), value: "\(AppFormatters.formatWeightNumber(e1rm))\(weightUnit)")
                                    }
                            }
                        }
                        .chartYAxisLabel(weightUnit)
                        .chartXSelection(value: $chartSelectedDate)
                        .modernChartDateValueAxes()
                        .frame(height: 160)
                    }
                }
            }
        }
    }

    // MARK: - Comparison

    private var comparisonSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_comparison"))
                switch viewModel.exerciseKind {
                case .strength, .weightedBodyweight:
                    comparisonRow(label: String(localized: "exercise_detail_delta_volume"), delta: viewModel.comparison.previousVolumeDelta, unit: weightUnit)
                    comparisonRow(label: String(localized: "exercise_detail_delta_weight"), delta: viewModel.comparison.previousWeightDelta, unit: weightUnit)
                    comparisonRow(label: String(localized: "exercise_detail_delta_avg5"), delta: viewModel.comparison.averageFiveVolumeDelta, unit: weightUnit)
                case .time:
                    comparisonRowSeconds(label: String(localized: "exercise_detail_comparison_time_total_delta"), delta: viewModel.comparison.previousVolumeDelta)
                    comparisonRowSeconds(label: String(localized: "exercise_detail_comparison_time_max_delta"), delta: viewModel.comparison.previousWeightDelta)
                    comparisonRowSeconds(label: String(localized: "exercise_detail_delta_avg5"), delta: viewModel.comparison.averageFiveVolumeDelta)
                case .cardio:
                    comparisonRowMeters(label: String(localized: "exercise_detail_comparison_dist_total_delta"), delta: viewModel.comparison.previousVolumeDelta)
                    comparisonRowMeters(label: String(localized: "exercise_detail_comparison_dist_max_delta"), delta: viewModel.comparison.previousWeightDelta)
                    comparisonRowMeters(label: String(localized: "exercise_detail_delta_avg5"), delta: viewModel.comparison.averageFiveVolumeDelta)
                }
            }
        }
    }

    private func comparisonRowSeconds(label: String, delta: Double) -> some View {
        let v = Int(delta.rounded())
        return HStack {
            Text(label)
                .font(AppTheme.bodyTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text("\(v >= 0 ? "+" : "")\(v)\(String(localized: "unit_seconds"))")
                .font(AppTheme.bodySemiboldFont)
                .foregroundStyle(delta >= 0 ? AppTheme.accent : AppTheme.destructive)
        }
    }

    private func comparisonRowMeters(label: String, delta: Double) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.bodyTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text("\(delta >= 0 ? "+" : "")\(AppFormatters.formatWeightNumber(delta))m")
                .font(AppTheme.bodySemiboldFont)
                .foregroundStyle(delta >= 0 ? AppTheme.accent : AppTheme.destructive)
        }
    }

    private func comparisonRow(label: String, delta: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.bodyTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text("\(AppFormatters.formatWeightNumber(delta)) \(unit)")
                .font(AppTheme.bodySemiboldFont)
                .foregroundStyle(delta >= 0 ? AppTheme.accent : AppTheme.destructive)
        }
    }

    // MARK: - KPI

    private var kpiSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "section_kpi"))
                switch viewModel.exerciseKind {
                case .strength, .weightedBodyweight:
                    InlineStatView(label: String(localized: "exercise_detail_kpi_recent"), value: "\(AppFormatters.formatWeightNumber(viewModel.kpi.recentWeight))\(weightUnit) × \(viewModel.kpi.recentReps)\(String(localized: "unit_reps"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_max_weight"), value: "\(AppFormatters.formatWeightNumber(viewModel.kpi.maxWeight))\(weightUnit)")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_max_reps"), value: "\(viewModel.kpi.maxReps)\(String(localized: "unit_reps"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_max_volume"), value: "\(AppFormatters.formatWeightNumber(viewModel.kpi.maxSessionVolume))\(weightUnit)")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_count"), value: "\(viewModel.kpi.executionCount)\(String(localized: "unit_times"))")
                case .time:
                    InlineStatView(label: String(localized: "exercise_detail_kpi_time_recent_longest"), value: "\(viewModel.kpi.recentLongestDurationSeconds)\(String(localized: "unit_seconds"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_time_max_longest"), value: "\(viewModel.kpi.maxLongestDurationSeconds)\(String(localized: "unit_seconds"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_time_recent_session_total"), value: "\(viewModel.kpi.recentSessionTotalDurationSeconds)\(String(localized: "unit_seconds"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_time_max_session_total"), value: "\(viewModel.kpi.maxSessionTotalDurationSeconds)\(String(localized: "unit_seconds"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_count"), value: "\(viewModel.kpi.executionCount)\(String(localized: "unit_times"))")
                case .cardio:
                    InlineStatView(label: String(localized: "exercise_detail_kpi_cardio_recent_dist"), value: "\(AppFormatters.formatWeightNumber(viewModel.kpi.recentTotalDistanceMeters / 1000))\(String(localized: "unit_km"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_cardio_max_dist"), value: "\(AppFormatters.formatWeightNumber(viewModel.kpi.maxSingleDistanceMeters / 1000))\(String(localized: "unit_km"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_cardio_recent_duration"), value: "\(viewModel.kpi.recentTotalCardioDurationSeconds)\(String(localized: "unit_seconds"))")
                    InlineStatView(label: String(localized: "exercise_detail_kpi_count"), value: "\(viewModel.kpi.executionCount)\(String(localized: "unit_times"))")
                }
            }
        }
    }

    // MARK: - History

    private var historyCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_history"))
                if filteredHistory.isEmpty {
                    Text(String(localized: "exercise_detail_no_records"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.vertical, AppTheme.spacingMD)
                } else {
                    let stats = WorkoutStatsService(modelContext: modelContext)
                    ForEach(filteredHistory, id: \.0.id) { we, session in
                        historyRow(we: we, session: session, stats: stats)
                        if we.id != filteredHistory.last?.0.id {
                            MemoFlowHairlineDivider()
                        }
                    }
                }
            }
        }
    }

    private func historyRow(we: WorkoutExercise, session: WorkoutSession, stats: WorkoutStatsService) -> some View {
        let sets = we.sets.sorted { $0.orderIndex < $1.orderIndex }
        let date = session.endedAt ?? session.startedAt
        let kind = ExerciseKind(stored: we.exercise?.exerciseKind)
        return VStack(alignment: .leading, spacing: 4) {
            Text(AppFormatters.formatDateWithWeekday(date))
                .font(AppTheme.bodySemiboldFont)
                .foregroundStyle(AppTheme.primaryText)
            HStack(spacing: AppTheme.spacingSM) {
                switch kind {
                case .strength, .weightedBodyweight:
                    MetricChip(text: "\(AppFormatters.formatWeightNumber(stats.totalVolume(for: we)))\(weightUnit)")
                case .time:
                    let totalSec = sets.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
                    MetricChip(text: "\(totalSec)\(String(localized: "unit_seconds")) \(String(localized: "exercise_detail_history_total_time"))")
                case .cardio:
                    let dist = sets.reduce(0.0) { $0 + ($1.distanceMeters ?? 0) }
                    MetricChip(text: "\(AppFormatters.formatWeightNumber(dist / 1000))\(String(localized: "unit_km"))")
                }
                MetricChip(text: "\(sets.count)\(String(localized: "unit_sets"))")
            }
            switch kind {
            case .strength, .weightedBodyweight:
                if let bestSet = sets.filter({ $0.weight != nil && $0.reps != nil }).max(by: { (($0.weight ?? 0) * Double($0.reps ?? 0)) < (($1.weight ?? 0) * Double($1.reps ?? 0)) }) {
                    Text("\(String(localized: "exercise_detail_best_set")) \(AppFormatters.formatWeight(bestSet.weight, unit: weightUnit)) × \(bestSet.reps ?? 0)\(String(localized: "unit_reps"))")
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            case .time:
                if let maxS = sets.map({ $0.durationSeconds ?? 0 }).max(), maxS > 0 {
                    Text("\(String(localized: "exercise_detail_best_set")) \(maxS)\(String(localized: "unit_seconds"))")
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            case .cardio:
                let bestDist = sets.map { $0.distanceMeters ?? 0 }.max() ?? 0
                if bestDist > 0 {
                    Text("\(String(localized: "exercise_detail_best_set")) \(AppFormatters.formatWeightNumber(bestDist / 1000))\(String(localized: "unit_km"))")
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            if let m = we.freeMemo?.trimmingCharacters(in: .whitespacesAndNewlines), !m.isEmpty {
                Text(m)
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.tertiaryText)
                    .lineLimit(4)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Next session hint

    @ViewBuilder
    private var nextSessionInsightCard: some View {
        if let text = nextSessionInsightText() {
            SectionCard {
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.accent)
                        Text(String(localized: "exercise_detail_next_hint_title"))
                            .font(AppTheme.bodySemiboldFont)
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    Text(text)
                        .font(AppTheme.bodyTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private func nextSessionInsightText() -> String? {
        guard !viewModel.trendPoints.isEmpty else { return nil }
        let c = viewModel.comparison
        switch viewModel.exerciseKind {
        case .strength, .weightedBodyweight:
            let dv = c.previousVolumeDelta
            let dw = c.previousWeightDelta
            if abs(dv) < 0.01, abs(dw) < 0.01 {
                return String(localized: "exercise_detail_insight_next_flat")
            }
            if dv > 0, dw >= 0 {
                return String(localized: "exercise_detail_insight_next_progress")
            }
            if dv < 0 || dw < 0 {
                return String(localized: "exercise_detail_insight_next_recovery")
            }
            return String(localized: "exercise_detail_insight_next_mixed")
        case .time:
            let dt = c.previousVolumeDelta
            let dm = c.previousWeightDelta
            if abs(dt) < 0.5, abs(dm) < 0.5 {
                return String(localized: "exercise_detail_insight_next_flat_time")
            }
            if dt > 0 || dm > 0 {
                return String(localized: "exercise_detail_insight_next_progress_time")
            }
            return String(localized: "exercise_detail_insight_next_recovery_time")
        case .cardio:
            let dd = c.previousVolumeDelta
            let dm = c.previousWeightDelta
            if abs(dd) < 0.5, abs(dm) < 0.5 {
                return String(localized: "exercise_detail_insight_next_flat_cardio")
            }
            if dd > 0 || dm > 0 {
                return String(localized: "exercise_detail_insight_next_progress_cardio")
            }
            return String(localized: "exercise_detail_insight_next_recovery_cardio")
        }
    }

    // MARK: - PR milestone history (strength)

    private var prMilestoneHistorySection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                SectionHeaderView(title: String(localized: "exercise_detail_pr_history_title"))
                Text(String(localized: "exercise_detail_pr_history_footer"))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
                ForEach(viewModel.prMilestones) { m in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(AppFormatters.formatDateWithWeekday(m.date))
                                .font(AppTheme.bodySemiboldFont)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(
                                "\(AppFormatters.formatWeight(m.weight, unit: weightUnit)) × \(m.reps)\(String(localized: "unit_reps")) · \(AppFormatters.formatWeightNumber(m.volume))\(weightUnit) \(String(localized: "unit_lifted"))"
                            )
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.spacingXS)
                }
            }
        }
    }

    // MARK: - Helpers

    private func closestChartPoint(to date: Date) -> ChartDataPoint? {
        chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private func loadAllExercises() {
        do {
            allExercises = try ExerciseRepository(modelContext: modelContext).fetchAllExercises()
        } catch {
            allExercises = []
        }
    }

    private func exportExerciseCSV() {
        guard let eid = currentExerciseId else { return }
        let now = Date()
        let toExclusive = now.addingTimeInterval(1)
        let csv: String?
        if selectedPeriod == .all {
            csv = try? ExportService.buildExerciseCSV(modelContext: modelContext, exerciseId: eid, weightUnit: weightUnit, from: nil, to: nil)
        } else if let start = selectedPeriod.startDate() {
            csv = try? ExportService.buildExerciseCSV(modelContext: modelContext, exerciseId: eid, weightUnit: weightUnit, from: start, to: toExclusive)
        } else {
            csv = try? ExportService.buildExerciseCSV(modelContext: modelContext, exerciseId: eid, weightUnit: weightUnit, from: nil, to: nil)
        }
        guard let csv, let url = ExportService.writeExerciseExportToTempFile(csv: csv) else { return }
        AnalyticsEventService.log(.csvExported(kind: "exercise_period"))
        exportFileURL = url
    }

    private func load() {
        viewModel.load(modelContext: modelContext, exerciseId: currentExerciseId ?? exerciseId, start: periodStart)
    }
}

// MARK: - Premium CTA (shared)

struct PremiumCTAView: View {
    var analyticsSource: String = "unknown"
    private let premium = PremiumService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.memoSectionGap) {
                SectionCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                        SectionHeaderView(title: String(localized: "premium_header"))
                        featureRow(icon: "chart.line.uptrend.xyaxis", text: String(localized: "premium_feature_graphs"))
                        featureRow(icon: "icloud.fill", text: String(localized: "premium_feature_icloud"))
                        featureRow(icon: "applewatch", text: String(localized: "premium_feature_watch"))
                        featureRow(icon: "square.and.arrow.up", text: String(localized: "premium_feature_csv"))
                    }
                }
                SectionCard {
                    VStack(spacing: AppTheme.spacingMD) {
                        if let product = premium.product {
                            HStack {
                                Text(String(localized: "premium_price"))
                                    .font(AppTheme.bodyTypographyFont)
                                    .foregroundStyle(AppTheme.primaryText)
                                Spacer()
                                Text(product.displayPrice)
                                    .font(AppTheme.numericEmphasisFont)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            PrimaryButton(
                                title: String(localized: "premium_purchase"),
                                action: { Task { await premium.purchase() } },
                                isDisabled: premium.isPurchasing
                            )
                        }
                        Button(String(localized: "premium_restore")) {
                            Task { await premium.restore() }
                        }
                        .font(AppTheme.bodyTypographyFont)
                        .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
        }
        .background(AppTheme.appBackground)
        .navigationTitle(String(localized: "premium_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsEventService.log(.premiumPromoOpened(source: analyticsSource))
            Task { await premium.loadProduct() }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            Text(text)
                .font(AppTheme.bodyTypographyFont)
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exerciseId: UUID(), exerciseName: "ベンチプレス")
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, WorkoutSet.self, PersonalRecord.self], inMemory: true)
}
