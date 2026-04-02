// File: Modules/Workout/WorkoutExerciseEditorBlock.swift
// 1 種目分の記録 UI（WorkoutRecordView / WorkoutSessionFlowView で共有）

import SwiftUI

struct WorkoutExerciseEditorBlock: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @AppStorage(AppTheme.simpleSetInputStorageKey) private var simpleSetInputMode: Bool = false
    @Bindable var viewModel: WorkoutRecordViewModel
    let exerciseIndex: Int
    var onExerciseNameTap: () -> Void
    /// `nil` のときは設定（`@AppStorage`）に従う。特定画面だけ別単位で表示したい場合に `"kg"` / `"lb"` を渡す。
    var weightUnitOverride: String? = nil
    /// 単一種目（セッションフロー）向け: 前回パネル拡張・表ヘッダー「重さ/回数」・FAB 用にインライン追加を隠す
    var useMemoSessionChrome: Bool = false

    @State private var isMemoTableExpanded: Bool = true

    private var effectiveWeightUnit: String {
        weightUnitOverride ?? weightUnit
    }

    @ViewBuilder
    private var exerciseDraftBody: some View {
        if exerciseIndex < viewModel.draft.exercises.count {
            let exerciseDraft = viewModel.draft.exercises[exerciseIndex]
            exerciseCardContent(exerciseDraft: exerciseDraft)
        }
    }

    var body: some View {
        exerciseDraftBody
    }

    private func exerciseCardContent(exerciseDraft: WorkoutExerciseDraft) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            exerciseNameHeader(exerciseDraft: exerciseDraft, tableExpanded: $isMemoTableExpanded)

            if !useMemoSessionChrome || isMemoTableExpanded {
            VStack(alignment: .leading, spacing: useMemoSessionChrome ? 0 : AppTheme.spacingLG) {
                if useMemoSessionChrome {
                    if let panelData = viewModel.previousRecordPanelData(exerciseId: exerciseDraft.exerciseId, weightUnit: effectiveWeightUnit) {
                        PreviousRecordPanelView(
                            dateString: panelData.date,
                            setLines: panelData.setLines,
                            memoChrome: true,
                            exerciseId: exerciseDraft.exerciseId,
                            exerciseName: exerciseDraft.exerciseName,
                            onCopyAll: viewModel.canApplyPreviousSessionToExercise(exerciseIndex: exerciseIndex)
                                ? {
                                    HapticHelper.light()
                                    viewModel.applyPreviousSessionToExercise(exerciseIndex: exerciseIndex)
                                }
                                : nil
                        )
                        MemoFlowHairlineDivider()
                            .padding(.vertical, 2)
                    }
                } else {
                    if viewModel.canApplyPreviousSessionToExercise(exerciseIndex: exerciseIndex) {
                        Button {
                            HapticHelper.light()
                            viewModel.applyPreviousSessionToExercise(exerciseIndex: exerciseIndex)
                        } label: {
                            HStack(spacing: AppTheme.spacingSM) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                Text(String(localized: "workout_apply_previous_sets"))
                                    .font(AppTheme.bodySecondaryFont.weight(.medium))
                            }
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, AppTheme.spacingSM)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(String(localized: "workout_apply_previous_sets_hint"))
                    }

                    if let panelData = viewModel.previousRecordPanelData(exerciseId: exerciseDraft.exerciseId, weightUnit: effectiveWeightUnit) {
                        PreviousRecordPanelView(
                            dateString: panelData.date,
                            setLines: panelData.setLines,
                            memoChrome: false,
                            exerciseId: exerciseDraft.exerciseId,
                            exerciseName: exerciseDraft.exerciseName,
                            onCopyAll: nil
                        )
                        Divider()
                            .background(Color(uiColor: .separator))
                            .padding(.vertical, AppTheme.spacingSM)
                    }
                }

                setTableStack(exerciseDraft: exerciseDraft)
                .background(AppTheme.memoRecordSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: useMemoSessionChrome ? 0 : AppTheme.spacingXS) {
                    Text(String(localized: "workout_memo_optional"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: useMemoSessionChrome ? AppTheme.memoStrengthRowMinHeight : 0, alignment: .leading)
                    TextField(
                        String(localized: "workout_memo_placeholder"),
                        text: Binding(
                            get: { viewModel.draft.exercises[exerciseIndex].freeMemo },
                            set: { viewModel.setFreeMemo(exerciseIndex: exerciseIndex, $0) }
                        )
                    )
                    .lineLimit(1)
                    .font(useMemoSessionChrome ? AppTheme.memoStrengthNumericInputFont : AppTheme.bodyTypographyFont)
                    .padding(.horizontal, AppTheme.spacingSM)
                    .padding(.vertical, useMemoSessionChrome ? 0 : AppTheme.memoCompactFieldPaddingV)
                    .frame(
                        minHeight: useMemoSessionChrome ? AppTheme.memoStrengthRowMinHeight : 80,
                        maxHeight: useMemoSessionChrome ? AppTheme.memoStrengthRowMinHeight : nil,
                        alignment: .center
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.memoInputCellFill)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.memoSetFieldCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.memoSetFieldCornerRadius, style: .continuous)
                            .stroke(AppTheme.inputFieldBorder, lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // MEMO セッション風の「再生」/「トレーニングプラン」表示は今後実装予定がないため非表示
            }
            .padding(useMemoSessionChrome ? AppTheme.memoRecordBlockInnerPadding : AppTheme.spacingLG)
            }
        }
        .background(AppTheme.memoRecordSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.5)
        )
        .overlay(
            Group {
                if viewModel.isInSuperset(exerciseIndex: exerciseIndex) {
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.45), lineWidth: 2)
                }
            }
        )
    }


    @ViewBuilder
    private func setTableStack(exerciseDraft: WorkoutExerciseDraft) -> some View {
        let kind = viewModel.exerciseKind(at: exerciseIndex)
        let showMetaColumns = useMemoSessionChrome && !simpleSetInputMode && (kind == .strength || kind == .weightedBodyweight)
        let memoActionW = showMetaColumns ? AppTheme.memoFlowActionClusterWidthNarrow : AppTheme.memoFlowActionClusterWidth

        VStack(alignment: .leading, spacing: 0) {
            if useMemoSessionChrome {
                VStack(alignment: .leading, spacing: 0) {
                    SetTableHeaderRow(
                        exerciseKind: kind,
                        weightUnit: effectiveWeightUnit,
                        memoStyleHeaders: true,
                        cardioInputStyle: exerciseDraft.cardioInputStyle,
                        showSetMetaColumns: showMetaColumns,
                        memoActionClusterWidth: memoActionW
                    )
                    ForEach(Array(exerciseDraft.sets.enumerated()), id: \.element.id) { setIndex, _ in
                        setRowView(setIndex: setIndex)
                            .contextMenu {
                                Button(String(localized: "workout_delete_set"), role: .destructive) {
                                    viewModel.removeSets(exerciseIndex: exerciseIndex, at: IndexSet(integer: setIndex))
                                }
                            }
                        if setIndex < exerciseDraft.sets.count - 1 {
                            MemoFlowHairlineDivider()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                SetTableHeaderRow(
                    exerciseKind: kind,
                    weightUnit: effectiveWeightUnit,
                    memoStyleHeaders: false,
                    cardioInputStyle: exerciseDraft.cardioInputStyle
                )
                ForEach(Array(exerciseDraft.sets.enumerated()), id: \.element.id) { setIndex, _ in
                    setRowView(setIndex: setIndex)
                        .contextMenu {
                            Button(String(localized: "workout_delete_set"), role: .destructive) {
                                viewModel.removeSets(exerciseIndex: exerciseIndex, at: IndexSet(integer: setIndex))
                            }
                        }
                    if setIndex < exerciseDraft.sets.count - 1 {
                        Divider()
                    }
                }
            }

            if useMemoSessionChrome {
                MemoFlowHairlineDivider()
            } else {
                Divider()
            }

            Button {
                HapticHelper.light()
                viewModel.addSet(exerciseIndex: exerciseIndex)
            } label: {
                if useMemoSessionChrome {
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text(String(localized: "workout_add_set"))
                            .font(AppTheme.captionTypographyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, AppTheme.spacingSM)
                    .frame(height: AppTheme.memoStrengthRowMinHeight)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text(String(localized: "workout_add_set"))
                            .font(AppTheme.bodySemiboldFont)
                    }
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "workout_add_set"))
        }
    }

    private func setRowView(setIndex: Int) -> some View {
        SetRowView(
            exerciseKind: viewModel.exerciseKind(at: exerciseIndex),
            orderIndex: setIndex,
            weight: primaryFieldBinding(setIndex: setIndex),
            reps: secondaryFieldBinding(setIndex: setIndex),
            setType: Binding(
                get: { viewModel.setTypeString(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                set: { viewModel.setSetType(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
            ),
            rpe: Binding(
                get: { viewModel.rpeValue(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                set: { viewModel.setRpe(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
            ),
            isAssisted: Binding(
                get: { viewModel.isAssisted(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                set: { viewModel.setAssisted(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
            ),
            isCompleted: Binding(
                get: { viewModel.isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                set: { viewModel.setCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
            ),
            canApplyPrevious: viewModel.canApplyPreviousForRow(exerciseIndex: exerciseIndex, setIndex: setIndex),
            onApplyPrevious: { viewModel.applyPreviousToRow(exerciseIndex: exerciseIndex, setIndex: setIndex) },
            canCopyFromAbove: viewModel.canCopyFromRowAbove(exerciseIndex: exerciseIndex, setIndex: setIndex),
            onCopyFromAbove: { viewModel.copyFromRowAbove(exerciseIndex: exerciseIndex, setIndex: setIndex) },
            onDelete: { viewModel.removeSets(exerciseIndex: exerciseIndex, at: IndexSet(integer: setIndex)) },
            weightUnitDisplay: weightUnitOverride,
            memoFlowInputStyle: useMemoSessionChrome,
            cardioInputStyle: exerciseIndex < viewModel.draft.exercises.count
                ? viewModel.draft.exercises[exerciseIndex].cardioInputStyle
                : nil,
            treadmillDuration: viewModel.isTreadmillCardio(exerciseIndex: exerciseIndex)
                ? Binding(
                    get: { viewModel.durationString(exerciseIndex: exerciseIndex, setIndex: setIndex) },
                    set: { viewModel.setDuration(exerciseIndex: exerciseIndex, setIndex: setIndex, $0) }
                )
                : nil
        )
    }

    private func exerciseNameHeader(exerciseDraft: WorkoutExerciseDraft, tableExpanded: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: AppTheme.spacingSM) {
            HStack(alignment: .center, spacing: AppTheme.spacingSM) {
                Button {
                    HapticHelper.light()
                    onExerciseNameTap()
                } label: {
                    Text(exerciseDraft.exerciseName)
                        .font(useMemoSessionChrome ? AppTheme.exerciseRecordHeaderTitleFont : AppTheme.exerciseNameInCardFont)
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "workout_show_exercise_detail"))

                if viewModel.isInSuperset(exerciseIndex: exerciseIndex) {
                    Text(String(localized: "workout_superset"))
                        .font(AppTheme.smallCaptionFont)
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, AppTheme.spacingSM)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if useMemoSessionChrome {
                Button {
                    HapticHelper.light()
                    tableExpanded.wrappedValue.toggle()
                } label: {
                    Image(systemName: tableExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tableExpanded.wrappedValue ? String(localized: "workout_collapse_exercise") : String(localized: "workout_expand_exercise"))
            }

            Menu {
                if viewModel.canLinkSupersetWithNext(exerciseIndex: exerciseIndex) {
                    Button {
                        HapticHelper.light()
                        viewModel.linkSupersetWithNext(exerciseIndex: exerciseIndex)
                    } label: {
                        Label(String(localized: "workout_link_superset"), systemImage: "link")
                    }
                }
                if viewModel.isInSuperset(exerciseIndex: exerciseIndex) {
                    Button(role: .destructive) {
                        HapticHelper.light()
                        viewModel.unlinkSuperset(exerciseIndex: exerciseIndex)
                    } label: {
                        Label(String(localized: "workout_unlink_superset"), systemImage: "link.slash")
                    }
                }
                if viewModel.canMarkAllWarmup(exerciseIndex: exerciseIndex) {
                    Button {
                        HapticHelper.light()
                        viewModel.markAllSetsWarmup(exerciseIndex: exerciseIndex)
                    } label: {
                        Label(String(localized: "workout_mark_all_warmup"), systemImage: "flame")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.caption)
                    .foregroundStyle(AppTheme.memoNavBarForeground)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "workout_exercise_options"))

            HStack(spacing: AppTheme.spacingXS) {
                Button {
                    HapticHelper.light()
                    viewModel.moveExercise(from: exerciseIndex, to: exerciseIndex - 1)
                } label: {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(exerciseIndex <= 0)
                .opacity(exerciseIndex <= 0 ? 0.4 : 1)
                .accessibilityLabel(String(localized: "workout_move_exercise_up"))
                .accessibilityHint(String(localized: "exercise_reorder_hint"))
                Button {
                    HapticHelper.light()
                    viewModel.moveExercise(from: exerciseIndex, to: exerciseIndex + 1)
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(exerciseIndex >= viewModel.draft.exercises.count - 1)
                .opacity(exerciseIndex >= viewModel.draft.exercises.count - 1 ? 0.4 : 1)
                .accessibilityLabel(String(localized: "workout_move_exercise_down"))
                .accessibilityHint(String(localized: "exercise_reorder_hint"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, useMemoSessionChrome ? AppTheme.memoRecordBlockInnerPadding : AppTheme.spacingLG)
        .padding(.vertical, useMemoSessionChrome ? 0 : AppTheme.spacingLG)
        .frame(minHeight: useMemoSessionChrome ? AppTheme.memoStrengthRowMinHeight : 0)
        .background(AppTheme.memoSolidExerciseHeaderBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 0.5)
        }
    }

    private func primaryFieldBinding(setIndex: Int) -> Binding<String> {
        let kind = viewModel.exerciseKind(at: exerciseIndex)
        let treadmill = viewModel.isTreadmillCardio(exerciseIndex: exerciseIndex)
        return Binding(
            get: {
                switch kind {
                case .strength, .weightedBodyweight:
                    return viewModel.weightString(exerciseIndex: exerciseIndex, setIndex: setIndex)
                case .time:
                    return viewModel.durationString(exerciseIndex: exerciseIndex, setIndex: setIndex)
                case .cardio:
                    if treadmill {
                        return viewModel.inclinePercentString(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    }
                    return viewModel.distanceKmString(exerciseIndex: exerciseIndex, setIndex: setIndex)
                }
            },
            set: { s in
                switch kind {
                case .strength, .weightedBodyweight:
                    viewModel.setWeight(exerciseIndex: exerciseIndex, setIndex: setIndex, s)
                case .time:
                    viewModel.setDuration(exerciseIndex: exerciseIndex, setIndex: setIndex, s)
                case .cardio:
                    if treadmill {
                        viewModel.setInclinePercent(exerciseIndex: exerciseIndex, setIndex: setIndex, s)
                    } else {
                        viewModel.setDistanceKm(exerciseIndex: exerciseIndex, setIndex: setIndex, s)
                    }
                }
            }
        )
    }

    private func secondaryFieldBinding(setIndex: Int) -> Binding<String> {
        let kind = viewModel.exerciseKind(at: exerciseIndex)
        let treadmill = viewModel.isTreadmillCardio(exerciseIndex: exerciseIndex)
        return Binding(
            get: {
                switch kind {
                case .strength, .weightedBodyweight:
                    return viewModel.repsString(exerciseIndex: exerciseIndex, setIndex: setIndex)
                case .time:
                    return ""
                case .cardio:
                    if treadmill {
                        return viewModel.speedKmhString(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    }
                    return viewModel.durationString(exerciseIndex: exerciseIndex, setIndex: setIndex)
                }
            },
            set: { s in
                switch kind {
                case .strength, .weightedBodyweight:
                    viewModel.setReps(exerciseIndex: exerciseIndex, setIndex: setIndex, s)
                case .time:
                    break
                case .cardio:
                    if treadmill {
                        viewModel.setSpeedKmh(exerciseIndex: exerciseIndex, setIndex: setIndex, s)
                    } else {
                        viewModel.setDuration(exerciseIndex: exerciseIndex, setIndex: setIndex, s)
                    }
                }
            }
        )
    }

}
