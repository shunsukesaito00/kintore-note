import SwiftUI
import SwiftData
import Charts

/// 種目別タブ: 登録種目を一覧（株アプリ風の行＋スパークライン）で表示
struct GrowthExerciseTab: View {
    let viewModel: StatisticsViewModel
    let weightUnit: String

    @Environment(\.modelContext) private var modelContext
    @State private var selectedPeriod: ExerciseTrendPeriod = .sixMonths

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionBlockSpacing) {
                periodPicker
                if viewModel.allExercises.isEmpty {
                    Text(String(localized: "growth_exercise_no_data"))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppTheme.spacingLG)
                } else {
                    ForEach(viewModel.allExercises, id: \.id) { ex in
                        ExerciseStockRow(
                            exercise: ex,
                            displayWeightUnit: weightUnit,
                            period: selectedPeriod
                        )
                        .environment(\.modelContext, modelContext)
                    }
                }
            }
            .padding(.horizontal, AppTheme.screenHorizontalPaddingCompact)
            .padding(.top, AppTheme.screenEdgeTopPadding)
            .padding(.bottom, AppTheme.screenEdgeBottomPadding)
        }
        .background(AppTheme.appBackground)
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(ExerciseTrendPeriod.allCases, id: \.self) { period in
                let isSelected = selectedPeriod == period
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.displayName)
                        .font(AppTheme.captionTypographyFont)
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
}

private struct ExerciseStockRow: View {
    let exercise: Exercise
    let displayWeightUnit: String
    let period: ExerciseTrendPeriod

    @Environment(\.modelContext) private var modelContext
    @State private var detailVM = ExerciseDetailViewModel()

    var body: some View {
        NavigationLink(value: ExerciseNavLinkTarget(id: exercise.id, name: exercise.name)) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(2)
                    if detailVM.kpi.executionCount > 0, usesLoad {
                        HStack(spacing: 6) {
                            Text(String(localized: "growth_stock_max_weight"))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.tertiaryText)
                            Text(formattedMaxWeight(detailVM.kpi.maxWeight))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                Spacer(minLength: 8)
                miniChart
            }
            .padding(AppTheme.memoCardPadding)
            .background(AppTheme.memoRecordSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
            )
        }
        .buttonStyle(.plain)
        .task(id: exercise.id) {
            reload()
        }
        .onChange(of: period) { _, _ in
            reload()
        }
    }

    private var usesLoad: Bool {
        ExerciseKind(stored: exercise.exerciseKind).usesLoadVolume
    }

    private func reload() {
        detailVM.load(
            modelContext: modelContext,
            exerciseId: exercise.id,
            start: period.startDate()
        )
    }

    private func formattedMaxWeight(_ kg: Double) -> String {
        if displayWeightUnit == "lb" {
            return "\(AppFormatters.formatWeightNumber(AppFormatters.kilogramsToPounds(kg)))\(displayWeightUnit)"
        }
        return "\(AppFormatters.formatWeightNumber(kg))\(displayWeightUnit)"
    }

    @ViewBuilder
    private var miniChart: some View {
        let points = detailVM.trendPoints
        let kind = ExerciseKind(stored: exercise.exerciseKind)
        if points.isEmpty {
            Color.clear.frame(width: 100, height: 44)
        } else if kind.usesLoadVolume {
            Chart(points) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("W", displayYWeight(p.maxWeight))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppTheme.accent)
                AreaMark(
                    x: .value("Date", p.date),
                    y: .value("W", displayYWeight(p.maxWeight))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.accent.opacity(0.35), AppTheme.accent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(width: 100, height: 44)
        } else {
            Chart(points) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("V", p.totalVolume)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppTheme.accentSecondary)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(width: 100, height: 44)
        }
    }

    private func displayYWeight(_ kg: Double) -> Double {
        displayWeightUnit == "lb" ? AppFormatters.kilogramsToPounds(kg) : kg
    }
}
