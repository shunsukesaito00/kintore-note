import SwiftUI
import SwiftData
import Charts

// MARK: - Metric Segment

private enum StrengthMetric: String, CaseIterable {
    case maxWeight
    case e1rm
    case volume
    case reps

    var label: String {
        switch self {
        case .maxWeight: return String(localized: "metric_max_weight")
        case .e1rm:      return String(localized: "metric_e1rm")
        case .volume:    return String(localized: "metric_volume")
        case .reps:      return String(localized: "metric_reps")
        }
    }
}

private enum TimeMetric: String, CaseIterable {
    case totalTime
    case bestSet

    var label: String {
        switch self {
        case .totalTime: return String(localized: "metric_total_time")
        case .bestSet:   return String(localized: "metric_best_set")
        }
    }
}

private enum CardioMetric: String, CaseIterable {
    case distance
    case duration

    var label: String {
        switch self {
        case .distance: return String(localized: "metric_distance")
        case .duration: return String(localized: "metric_duration")
        }
    }
}

struct GrowthExerciseTab: View {
    let viewModel: StatisticsViewModel
    let weightUnit: String

    @Environment(\.modelContext) private var modelContext
    @State private var exerciseVM = ExerciseDetailViewModel()
    @State private var selectedExerciseId: UUID?
    @State private var selectedPeriod: ExerciseTrendPeriod = .sixMonths
    @State private var chartSelectedDate: Date?

    @State private var strengthMetric: StrengthMetric = .maxWeight
    @State private var timeMetric: TimeMetric = .totalTime
    @State private var cardioMetric: CardioMetric = .distance

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.memoSectionGap) {
                exerciseHeader
                periodPicker
                metricSegment
                mainChart
                deltaChipsSection
                kpiGrid
            }
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
        }
        .background(AppTheme.appBackground)
        .onAppear { syncAndLoad() }
        .onChange(of: selectedExerciseId) { _, _ in loadTrend() }
        .onChange(of: selectedPeriod) { _, _ in loadTrend() }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                if viewModel.allExercises.isEmpty {
                    Text(String(localized: "growth_exercise_no_data"))
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "growth_picker_exercise"))
                                .font(AppTheme.captionTypographyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text(selectedExerciseName)
                                .font(AppTheme.title3Font)
                                .foregroundStyle(AppTheme.primaryText)
                                .lineLimit(1)
                        }
                        Spacer()
                        Menu {
                            ForEach(viewModel.allExercises, id: \.id) { ex in
                                Button {
                                    selectedExerciseId = ex.id
                                    chartSelectedDate = nil
                                } label: {
                                    Label(ex.name, systemImage: selectedExerciseId == ex.id ? "checkmark" : "")
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                                .padding(AppTheme.spacingSM)
                                .background(AppTheme.accentSoft)
                                .clipShape(Circle())
                        }
                    }

                    if let kpi = kpiSummaryLine {
                        Text(kpi)
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private var selectedExerciseName: String {
        guard let id = selectedExerciseId,
              let ex = viewModel.allExercises.first(where: { $0.id == id }) else {
            return viewModel.allExercises.first?.name ?? ""
        }
        return ex.name
    }

    private var kpiSummaryLine: String? {
        let kpi = exerciseVM.kpi
        switch exerciseVM.exerciseKind {
        case .strength, .weightedBodyweight:
            guard kpi.executionCount > 0 else { return nil }
            return "\(kpi.executionCount)\(String(localized: "unit_times")) | \(String(localized: "exercise_detail_kpi_max_weight")): \(AppFormatters.formatWeightNumber(kpi.maxWeight))\(weightUnit)"
        case .time:
            guard kpi.executionCount > 0 else { return nil }
            return "\(kpi.executionCount)\(String(localized: "unit_times"))"
        case .cardio:
            guard kpi.executionCount > 0 else { return nil }
            return "\(kpi.executionCount)\(String(localized: "unit_times"))"
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(ExerciseTrendPeriod.allCases, id: \.self) { period in
                let isSelected = selectedPeriod == period
                Button {
                    selectedPeriod = period
                } label: {
                    HStack(spacing: 3) {
                        Text(period.displayName)
                            .font(AppTheme.captionTypographyFont)
                    }
                    .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
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

    // MARK: - Metric Segment

    @ViewBuilder
    private var metricSegment: some View {
        switch exerciseVM.exerciseKind {
        case .strength, .weightedBodyweight:
            let metrics = selectedExerciseUsesWeight
                ? StrengthMetric.allCases
                : StrengthMetric.allCases.filter { $0 != .e1rm }
            segmentPicker(items: metrics, selected: $strengthMetric, label: \.label)
        case .time:
            segmentPicker(items: TimeMetric.allCases, selected: $timeMetric, label: \.label)
        case .cardio:
            segmentPicker(items: CardioMetric.allCases, selected: $cardioMetric, label: \.label)
        }
    }

    private func segmentPicker<T: Hashable>(items: [T], selected: Binding<T>, label: KeyPath<T, String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                ForEach(items, id: \T.self) { item in
                    let isSelected = selected.wrappedValue == item
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected.wrappedValue = item
                            chartSelectedDate = nil
                        }
                    } label: {
                        Text(item[keyPath: label])
                            .font(AppTheme.captionTypographyFont.weight(.medium))
                            .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? AppTheme.accent : AppTheme.accentSoft)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Main Chart

    @ViewBuilder
    private var mainChart: some View {
        let points = exerciseVM.trendPoints
        if points.isEmpty {
            emptyState
        } else {
            SectionCard {
                chartContent(points: points)
                    .frame(height: 220)
            }
        }
    }

    @ViewBuilder
    private func chartContent(points: [ExerciseTrendPointDTO]) -> some View {
        switch exerciseVM.exerciseKind {
        case .strength, .weightedBodyweight:
            strengthChart(points: points)
        case .time:
            timeChart(points: points)
        case .cardio:
            cardioChart(points: points)
        }
    }

    @ViewBuilder
    private func strengthChart(points: [ExerciseTrendPointDTO]) -> some View {
        switch strengthMetric {
        case .maxWeight:
            lineChart(points: points, yValue: \.maxWeight, yLabel: weightUnit, annotationLabel: String(localized: "chart_label_weight"), color: AppTheme.accent) {
                "\(AppFormatters.formatWeightNumber($0.maxWeight))\(weightUnit)"
            }
        case .e1rm:
            let filtered = points.filter { $0.estimated1RM != nil }
            lineChart(points: filtered, yValue: { $0.estimated1RM ?? 0 }, yLabel: weightUnit, annotationLabel: String(localized: "growth_e1rm_title"), color: AppTheme.accentSecondary) {
                "\(AppFormatters.formatWeightNumber($0.estimated1RM ?? 0))\(weightUnit)"
            }
        case .volume:
            barChart(points: points, yValue: \.totalVolume, yLabel: weightUnit, annotationLabel: String(localized: "chart_label_volume")) {
                "\(AppFormatters.formatWeightNumber($0.totalVolume))\(weightUnit)"
            }
        case .reps:
            lineChart(points: points, yValue: { Double($0.totalReps) }, yLabel: String(localized: "chart_label_reps"), annotationLabel: String(localized: "chart_label_reps"), color: AppTheme.accentSecondary) {
                "\($0.totalReps)\(String(localized: "unit_reps"))"
            }
        }
    }

    @ViewBuilder
    private func timeChart(points: [ExerciseTrendPointDTO]) -> some View {
        switch timeMetric {
        case .totalTime:
            barChart(points: points, yValue: { Double($0.sessionTotalDurationSeconds) }, yLabel: String(localized: "unit_seconds"), annotationLabel: String(localized: "exercise_detail_chart_session_total_time")) {
                "\($0.sessionTotalDurationSeconds)\(String(localized: "unit_seconds"))"
            }
        case .bestSet:
            lineChart(points: points, yValue: { Double($0.sessionMaxDurationSeconds) }, yLabel: String(localized: "unit_seconds"), annotationLabel: String(localized: "exercise_detail_chart_best_set_duration"), color: AppTheme.accent) {
                "\($0.sessionMaxDurationSeconds)\(String(localized: "unit_seconds"))"
            }
        }
    }

    @ViewBuilder
    private func cardioChart(points: [ExerciseTrendPointDTO]) -> some View {
        switch cardioMetric {
        case .distance:
            barChart(points: points, yValue: { $0.sessionTotalDistanceMeters / 1000 }, yLabel: String(localized: "unit_km"), annotationLabel: String(localized: "exercise_detail_chart_session_distance")) {
                "\(AppFormatters.formatWeightNumber($0.sessionTotalDistanceMeters / 1000))\(String(localized: "unit_km"))"
            }
        case .duration:
            lineChart(points: points, yValue: { Double($0.sessionTotalCardioDurationSeconds) }, yLabel: String(localized: "unit_seconds"), annotationLabel: String(localized: "exercise_detail_chart_session_cardio_duration"), color: AppTheme.accentSecondary) {
                "\($0.sessionTotalCardioDurationSeconds)\(String(localized: "unit_seconds"))"
            }
        }
    }

    // MARK: - Generic Chart Builders

    private func lineChart(
        points: [ExerciseTrendPointDTO],
        yValue: @escaping (ExerciseTrendPointDTO) -> Double,
        yLabel: String,
        annotationLabel: String,
        color: Color,
        annotationValue: @escaping (ExerciseTrendPointDTO) -> String
    ) -> some View {
        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("日付", point.date), y: .value("Y", yValue(point)))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(ModernChartStyle.lineAreaGradient(for: color))
            }
            ForEach(points) { point in
                LineMark(x: .value("日付", point.date), y: .value("Y", yValue(point)))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color)
                    .lineStyle(ModernChartStyle.lineStroke())
                PointMark(x: .value("日付", point.date), y: .value("Y", yValue(point)))
                    .foregroundStyle(color)
                    .symbolSize(28)
            }
            if let selected = chartSelectedDate,
               let match = closestPoint(to: selected, in: points) {
                RuleMark(x: .value("選択", match.date))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(AppTheme.secondaryText)
                    .annotation(position: .top, alignment: .center) {
                        ChartAnnotationBubble(date: match.date, label: annotationLabel, value: annotationValue(match))
                    }
            }
        }
        .chartYAxisLabel(yLabel)
        .chartXSelection(value: $chartSelectedDate)
        .modernChartDateValueAxes()
    }

    private func barChart(
        points: [ExerciseTrendPointDTO],
        yValue: @escaping (ExerciseTrendPointDTO) -> Double,
        yLabel: String,
        annotationLabel: String,
        annotationValue: @escaping (ExerciseTrendPointDTO) -> String
    ) -> some View {
        Chart {
            ForEach(points) { point in
                BarMark(x: .value("日付", point.date), y: .value("Y", yValue(point)))
                    .foregroundStyle(AppTheme.accent.gradient)
                    .cornerRadius(4)
            }
            if let selected = chartSelectedDate,
               let match = closestPoint(to: selected, in: points) {
                RuleMark(x: .value("選択", match.date))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(AppTheme.secondaryText)
                    .annotation(position: .top, alignment: .center) {
                        ChartAnnotationBubble(date: match.date, label: annotationLabel, value: annotationValue(match))
                    }
            }
        }
        .chartYAxisLabel(yLabel)
        .chartXSelection(value: $chartSelectedDate)
        .modernChartDateValueAxes()
    }

    // MARK: - Delta Chips

    private var deltaChipsSection: some View {
        let points = exerciseVM.trendPoints
        return Group {
            if let latest = points.last, let previous = points.dropLast().last {
                switch exerciseVM.exerciseKind {
                case .strength, .weightedBodyweight:
                    let weightDelta = latest.maxWeight - previous.maxWeight
                    let volumeDelta = latest.totalVolume - previous.totalVolume
                    HStack(spacing: AppTheme.spacingSM) {
                        deltaChip(label: String(localized: "delta_label_weight"), delta: weightDelta, unit: weightUnit)
                        deltaChip(label: String(localized: "delta_label_volume"), delta: volumeDelta, unit: weightUnit)
                        Spacer()
                    }
                case .time:
                    let d1 = Double(latest.sessionTotalDurationSeconds - previous.sessionTotalDurationSeconds)
                    let d2 = Double(latest.sessionMaxDurationSeconds - previous.sessionMaxDurationSeconds)
                    HStack(spacing: AppTheme.spacingSM) {
                        deltaChip(label: String(localized: "exercise_detail_comparison_time_total_delta"), delta: d1, unit: String(localized: "unit_seconds"))
                        deltaChip(label: String(localized: "exercise_detail_comparison_time_max_delta"), delta: d2, unit: String(localized: "unit_seconds"))
                        Spacer()
                    }
                case .cardio:
                    let d1 = latest.sessionTotalDistanceMeters - previous.sessionTotalDistanceMeters
                    let d2 = latest.sessionMaxDistanceMeters - previous.sessionMaxDistanceMeters
                    HStack(spacing: AppTheme.spacingSM) {
                        deltaChip(label: String(localized: "exercise_detail_comparison_dist_total_delta"), delta: d1, unit: "m")
                        deltaChip(label: String(localized: "exercise_detail_comparison_dist_max_delta"), delta: d2, unit: "m")
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - KPI Grid

    @ViewBuilder
    private var kpiGrid: some View {
        let kpi = exerciseVM.kpi
        if kpi.executionCount > 0 {
            SectionCard {
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    SectionHeaderView(title: String(localized: "section_kpi"))
                    kpiContent(kpi: kpi)
                }
            }
        }
    }

    @ViewBuilder
    private func kpiContent(kpi: ExerciseKpiDTO) -> some View {
        switch exerciseVM.exerciseKind {
        case .strength, .weightedBodyweight:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingSM) {
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_recent"),
                    value: "\(AppFormatters.formatWeightNumber(kpi.recentWeight))\(weightUnit)×\(kpi.recentReps)"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_max_weight"),
                    value: "\(AppFormatters.formatWeightNumber(kpi.maxWeight))\(weightUnit)"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_max_reps"),
                    value: "\(kpi.maxReps)\(String(localized: "unit_reps"))"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_count"),
                    value: "\(kpi.executionCount)\(String(localized: "unit_times"))"
                )
            }
        case .time:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingSM) {
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_time_recent_longest"),
                    value: "\(kpi.recentLongestDurationSeconds)\(String(localized: "unit_seconds"))"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_time_max_longest"),
                    value: "\(kpi.maxLongestDurationSeconds)\(String(localized: "unit_seconds"))"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_time_recent_session_total"),
                    value: "\(kpi.recentSessionTotalDurationSeconds)\(String(localized: "unit_seconds"))"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_count"),
                    value: "\(kpi.executionCount)\(String(localized: "unit_times"))"
                )
            }
        case .cardio:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingSM) {
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_cardio_recent_dist"),
                    value: "\(AppFormatters.formatWeightNumber(kpi.recentTotalDistanceMeters / 1000))\(String(localized: "unit_km"))"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_cardio_max_dist"),
                    value: "\(AppFormatters.formatWeightNumber(kpi.maxSingleDistanceMeters / 1000))\(String(localized: "unit_km"))"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_cardio_recent_duration"),
                    value: "\(kpi.recentTotalCardioDurationSeconds)\(String(localized: "unit_seconds"))"
                )
                kpiCell(
                    label: String(localized: "exercise_detail_kpi_count"),
                    value: "\(kpi.executionCount)\(String(localized: "unit_times"))"
                )
            }
        }
    }

    private func kpiCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingSM)
        .background(AppTheme.inputFill.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        SectionCard {
            HStack {
                Spacer()
                VStack(spacing: 8) {
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
    }

    // MARK: - Helpers

    private var selectedExerciseUsesWeight: Bool {
        guard let exId = selectedExerciseId,
              let ex = viewModel.allExercises.first(where: { $0.id == exId }) else { return true }
        return ExerciseKind(stored: ex.exerciseKind).usesLoadVolume
    }

    private func syncAndLoad() {
        if selectedExerciseId == nil {
            selectedExerciseId = viewModel.allExercises.first?.id
        }
        loadTrend()
    }

    private func loadTrend() {
        guard let exId = selectedExerciseId else { return }
        exerciseVM.load(
            modelContext: modelContext,
            exerciseId: exId,
            start: selectedPeriod.startDate()
        )
    }

    private func closestPoint(to date: Date, in points: [ExerciseTrendPointDTO]) -> ExerciseTrendPointDTO? {
        points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private func deltaChip(label: String, delta: Double, unit: String) -> some View {
        let isPositive = delta >= 0
        let valueText: String
        if unit == String(localized: "unit_seconds") {
            valueText = "\(isPositive ? "+" : "")\(Int(delta.rounded()))\(unit)"
        } else if unit == "m" {
            valueText = "\(isPositive ? "+" : "")\(AppFormatters.formatWeightNumber(delta))\(unit)"
        } else {
            valueText = "\(isPositive ? "+" : "")\(AppFormatters.formatWeightNumber(delta))\(unit)"
        }
        return HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2.weight(.bold))
            Text("\(label) \(valueText)")
                .font(AppTheme.captionTypographyFont)
        }
        .foregroundStyle(isPositive ? AppTheme.accent : AppTheme.destructive)
        .padding(.horizontal, AppTheme.spacingSM)
        .padding(.vertical, AppTheme.spacingXS)
        .background((isPositive ? AppTheme.accent : AppTheme.destructive).opacity(0.1))
        .clipShape(Capsule())
    }
}
