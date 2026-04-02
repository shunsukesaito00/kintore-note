import SwiftUI

struct ExerciseNavTarget: Hashable {
    let id: UUID
    let name: String
}

struct SessionReviewContentView: View {
    let session: WorkoutSession
    let summary: SessionSummaryDTO?
    let weightUnit: String
    var showSessionHeader: Bool = true

    var body: some View {
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
            if showSessionHeader {
                SectionCard(useElevatedSurface: true) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                        Text(AppFormatters.formatDateWithWeekday(session.startedAt))
                            .font(AppTheme.sessionDateTitleFont)
                            .foregroundStyle(AppTheme.primaryText)
                        if let summary {
                            HStack(spacing: AppTheme.spacingSM) {
                                if let d = summary.durationSeconds {
                                    MetricChip(text: AppFormatters.formatDuration(seconds: d))
                                }
                                MetricChip(text: "\(summary.exerciseCount)\(String(localized: "unit_exercises"))")
                                MetricChip(text: "\(summary.setCount)\(String(localized: "unit_sets"))")
                                MetricChip(text: "\(summary.repCount)\(String(localized: "unit_reps_long"))")
                                MetricChip(text: "\(AppFormatters.formatWeightNumber(summary.totalVolume))\(weightUnit) \(String(localized: "unit_lifted"))")
                            }
                        }
                    }
                }
            }
            ForEach(exercises, id: \.id) { we in
                SessionReviewExerciseBlockView(
                    workoutExercise: we,
                    weightUnit: weightUnit
                )
            }
        }
    }
}

struct SessionReviewExerciseBlockView: View {
    let workoutExercise: WorkoutExercise
    let weightUnit: String

    var body: some View {
        let sets = workoutExercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        let exKind = ExerciseKind(stored: workoutExercise.exercise?.exerciseKind)
        let cardioStyle = workoutExercise.exercise?.cardioInputStyle
        return SectionCard(useElevatedSurface: true) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacingSM) {
                    if let exercise = workoutExercise.exercise {
                        NavigationLink(value: ExerciseNavTarget(id: exercise.id, name: exercise.name)) {
                            HStack(spacing: AppTheme.spacingXS) {
                                Text(exercise.name)
                                    .font(AppTheme.exerciseNameInCardFont)
                                    .foregroundStyle(AppTheme.accent)
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent.opacity(0.6))
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(String(localized: "common_exercise"))
                            .font(AppTheme.exerciseNameInCardFont)
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    if workoutExercise.supersetGroupId != nil {
                        Text(String(localized: "session_review_superset"))
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, AppTheme.spacingSM)
                            .padding(.vertical, AppTheme.spacingXS)
                            .background(AppTheme.accentSoft.opacity(0.45))
                            .clipShape(Capsule())
                    }
                }
                if exKind.usesLoadVolume {
                    Text("\(AppFormatters.formatWeightNumber(totalVolume(workoutExercise)))\(weightUnit) \(String(localized: "unit_lifted"))")
                        .font(AppTheme.exerciseVolumeSubtitleFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                SetTableHeaderRow(exerciseKind: exKind, weightUnit: weightUnit, cardioInputStyle: cardioStyle)
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    ForEach(sets, id: \.id) { set in
                        SessionReviewSetRowView(
                            set: set,
                            exerciseKind: exKind,
                            weightUnit: weightUnit,
                            cardioInputStyle: cardioStyle
                        )
                    }
                }
                if let memo = workoutExercise.freeMemo, !memo.isEmpty {
                    Text(memo)
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.top, AppTheme.spacingXS)
                }
            }
        }
    }

    private func totalVolume(_ workoutExercise: WorkoutExercise) -> Double {
        workoutExercise.sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }
    }
}

private struct SessionReviewSetRowView: View {
    let set: WorkoutSet
    let exerciseKind: ExerciseKind
    let weightUnit: String
    var cardioInputStyle: String? = nil

    private var isTreadmillCardio: Bool {
        exerciseKind == .cardio && cardioInputStyle == CardioInputStyle.treadmill.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: AppTheme.spacingMD) {
                HStack(spacing: 4) {
                    Text("\(set.orderIndex + 1)")
                        .font(AppTheme.setIndexLabelFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    if exerciseKind == .strength || exerciseKind == .weightedBodyweight,
                       set.isAssisted == true {
                        Text(String(localized: "session_review_assisted"))
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .frame(width: AppTheme.setTableSetColumnWidth, alignment: .leading)
                if isTreadmillCardio {
                    treadmillDetailColumns
                } else {
                    firstDetailColumn
                    secondDetailColumn
                }
            }
            if let note = set.setNote, !note.isEmpty {
                Text("\(String(localized: "session_review_memo_prefix"))\(note)")
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.leading, AppTheme.setTableSetColumnWidth)
            }
        }
    }

    private var treadmillDetailColumns: some View {
        HStack(spacing: AppTheme.spacingSM) {
            sessionReviewMetricColumn(
                value: set.inclinePercent.map { AppFormatters.formatWeightNumber($0) } ?? "—",
                unit: "%"
            )
            sessionReviewMetricColumn(
                value: set.speedKmh.map { AppFormatters.formatWeightNumber($0) } ?? "—",
                unit: String(localized: "unit_kmh")
            )
            sessionReviewMetricColumn(
                value: set.durationSeconds.map { "\($0)" } ?? "—",
                unit: String(localized: "unit_seconds")
            )
        }
    }

    private func sessionReviewMetricColumn(value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTheme.weightDisplayPrimaryFont)
                .foregroundStyle(AppTheme.primaryText)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
            Text(unit)
                .font(AppTheme.weightUnitSubscriptFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(width: AppTheme.setTableTreadmillFieldWidth, alignment: .center)
    }

    @ViewBuilder
    private var firstDetailColumn: some View {
        switch exerciseKind {
        case .strength, .weightedBodyweight:
            let numeric = AppFormatters.formatWeightNumericOnly(set.weight)
            VStack(spacing: 2) {
                Text(numeric)
                    .font(AppTheme.weightDisplayPrimaryFont)
                    .foregroundStyle(AppTheme.primaryText)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)
                Text(weightUnit)
                    .font(AppTheme.weightUnitSubscriptFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(width: AppTheme.setTableWeightColumnWidth, alignment: .center)
        case .time:
            VStack(spacing: 2) {
                Text(set.durationSeconds.map { "\($0)" } ?? "—")
                    .font(AppTheme.weightDisplayPrimaryFont)
                    .foregroundStyle(AppTheme.primaryText)
                Text(String(localized: "unit_seconds"))
                    .font(AppTheme.weightUnitSubscriptFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(width: AppTheme.setTableWeightColumnWidth, alignment: .center)
        case .cardio:
            VStack(spacing: 2) {
                Text(set.distanceMeters.map { AppFormatters.formatWeightNumber($0 / 1000) } ?? "—")
                    .font(AppTheme.weightDisplayPrimaryFont)
                    .foregroundStyle(AppTheme.primaryText)
                Text(String(localized: "unit_km"))
                    .font(AppTheme.weightUnitSubscriptFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(width: AppTheme.setTableWeightColumnWidth, alignment: .center)
        }
    }

    @ViewBuilder
    private var secondDetailColumn: some View {
        switch exerciseKind {
        case .strength, .weightedBodyweight:
            Text("\(set.reps ?? 0)")
                .font(AppTheme.repsDisplayPrimaryFont)
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: AppTheme.setTableRepsColumnWidth, alignment: .center)
        case .time:
            Text("—")
                .font(AppTheme.repsDisplayPrimaryFont)
                .foregroundStyle(AppTheme.tertiaryText)
                .frame(width: AppTheme.setTableRepsColumnWidth, alignment: .center)
        case .cardio:
            Text(set.durationSeconds.map { "\($0)" } ?? "—")
                .font(AppTheme.repsDisplayPrimaryFont)
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: AppTheme.setTableRepsColumnWidth, alignment: .center)
        }
    }
}
