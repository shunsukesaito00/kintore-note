// File: Modules/Workout/WorkoutRecordView.swift

import SwiftUI
import SwiftData
import StoreKit
import UIKit

private struct ExerciseSheetItem: Identifiable {
    let id: UUID
    let name: String
}

struct WorkoutRecordView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview
    let draft: WorkoutSessionDraft
    let onDismiss: () -> Void
    let onSaveSuccess: (UUID) -> Void

    @State private var viewModel: WorkoutRecordViewModel?
    @State private var showExercisePicker = false
    @State private var showBackConfirm = false
    @State private var showEndConfirm = false
    @State private var exerciseDetailSheetItem: ExerciseSheetItem?
    @State private var showFullScreenRest = false
    @State private var restTimer = RestTimerManager()

    var body: some View {
        Group {
            if let vm = viewModel {
                recordContent(vm: vm)
            } else {
                ProgressView(String(localized: "home_loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { createViewModelOnce() }
            }
        }
    }

    /// ViewModel を 1 回だけ作成し @State に保持。body 内で毎回 new しないことで再描画時の不安定を防ぐ。
    private func createViewModelOnce() {
        guard viewModel == nil else { return }
        let w = WorkoutRepository(modelContext: modelContext)
        let e = ExerciseRepository(modelContext: modelContext)
        let prev = PreviousRecordService(workoutRepository: w)
        let pr = PersonalRecordService(modelContext: modelContext)
        let settings = SettingsRepository(modelContext: modelContext)
        let v = WorkoutRecordViewModel(
            draft: draft,
            workoutRepository: w,
            exerciseRepository: e,
            previousRecordService: prev,
            personalRecordService: pr,
            settingsRepository: settings,
            restTimerManager: restTimer,
            modelContext: modelContext
        )
        v.onSaveSuccess = { savedId in
            HapticHelper.success()
            onSaveSuccess(savedId)
        }
        v.onRequestReview = { requestReview() }
        restTimer.restoreFromUserDefaults()
        v.loadPreviousRecords()
        viewModel = v
    }

    @ViewBuilder
    private func recordContent(vm: WorkoutRecordViewModel) -> some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.recordExerciseBlockSpacing) {
                    SessionSummaryHeaderView(viewModel: vm)
                    ForEach(Array(vm.draft.exercises.enumerated()), id: \.element.id) { exerciseIndex, exerciseDraft in
                        WorkoutExerciseEditorBlock(
                            viewModel: vm,
                            exerciseIndex: exerciseIndex,
                            onExerciseNameTap: { exerciseDetailSheetItem = ExerciseSheetItem(id: exerciseDraft.exerciseId, name: exerciseDraft.exerciseName) },
                            useMemoSessionChrome: true
                        )
                        .draggable(exerciseDraft.id.uuidString) {
                            Text(exerciseDraft.exerciseName)
                                .font(AppTheme.buttonLabelFont)
                                .foregroundStyle(AppTheme.primaryText)
                                .padding(AppTheme.spacingMD)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                                        .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
                                )
                        }
                        .dropDestination(for: String.self) { (strings, _) in
                            guard let first = strings.first,
                                  let uuid = UUID(uuidString: first),
                                  let sourceIndex = vm.draft.exercises.firstIndex(where: { $0.id == uuid }),
                                  sourceIndex != exerciseIndex else { return false }
                            HapticHelper.light()
                            vm.moveExercise(from: sourceIndex, to: exerciseIndex)
                            return true
                        }
                        .accessibilityHint(String(localized: "exercise_reorder_hint"))
                    }
                    .animation(AppTheme.animationOverlay(reduceMotion: reduceMotion), value: vm.draft.exercises.count)
                }
                .padding(.horizontal, AppTheme.memoCardPadding)
                .padding(.top, AppTheme.spacingSM)
                .padding(.bottom, 88)
            }
            .background(AppTheme.appBackground)
            Button {
                HapticHelper.light()
                showExercisePicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(AppTheme.memoFABGreen)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, AppTheme.memoCardPadding)
            .padding(.bottom, AppTheme.memoCardPadding)
            .opacity(vm.draft.exercises.count <= 1 ? 0.9 : 1)
            .accessibilityLabel(String(localized: "workout_start_add_exercise"))
            .accessibilityHint(String(localized: "fab_add_exercise_hint"))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.memoNavigationBarFill, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticHelper.light()
                        if vm.hasMeaningfulInput() {
                            showBackConfirm = true
                        } else {
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(AppTheme.captionTypographyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.memoNavBarForeground)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.28)))
                    }
                    .accessibilityLabel(String(localized: "workout_nav_back_a11y"))
                    .accessibilityHint(String(localized: "a11y_workout_discard_hint"))
                }
                ToolbarItem(placement: .principal) {
                    Group {
                        if vm.draft.exercises.count == 1, let first = vm.draft.exercises.first {
                            Text(first.exerciseName)
                        } else {
                            Text(AppFormatters.formatNavBarDate(vm.draft.startedAt))
                        }
                    }
                    .font(AppTheme.memoRecordNavigationTitleFont)
                    .foregroundStyle(AppTheme.memoNavBarForeground)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: 200)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        HapticHelper.light()
                        guard !vm.draft.exercises.isEmpty else { return }
                        vm.startManualRestFromToolbar()
                        showFullScreenRest = true
                    } label: {
                        Image(systemName: "timer")
                            .font(AppTheme.captionTypographyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.memoNavBarForeground)
                    }
                    .disabled(vm.draft.exercises.isEmpty)
                    .accessibilityLabel(String(localized: "workout_manual_start_rest"))
                    MemoNavBarWeightUnitPicker(selection: $weightUnit)
                    Button {
                        HapticHelper.light()
                        showEndConfirm = true
                    } label: {
                        Text(String(localized: "workout_save"))
                            .font(AppTheme.memoRecordCompactTitleFont)
                            .foregroundStyle(AppTheme.memoNavBarForeground)
                    }
                    .accessibilityLabel(String(localized: "workout_save"))
                    .accessibilityHint(String(localized: "workout_save_toolbar_hint"))
                }
            }
            .onAppear {
                restTimer.restoreFromUserDefaults()
                vm.reportRestToWatch(remaining: restTimer.remainingSeconds, exerciseName: vm.currentRestExerciseName)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                restTimer.restoreFromUserDefaults()
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(
                    onSelect: { exercise in
                        vm.addExercise(exercise)
                        showExercisePicker = false
                    },
                    memoSessionStyle: true
                )
                .environment(\.modelContext, modelContext)
                .standardSheetChrome()
            }
            .sheet(item: $exerciseDetailSheetItem) { item in
                NavigationStack {
                    ExerciseDetailView(exerciseId: item.id, exerciseName: item.name)
                        .environment(\.modelContext, modelContext)
                }
                .standardSheetChrome()
            }
            .alert(String(localized: "alert_discard_title"), isPresented: $showBackConfirm) {
                Button(String(localized: "common_cancel"), role: .cancel) { showBackConfirm = false }
                Button(String(localized: "alert_discard_confirm"), role: .destructive) {
                    showBackConfirm = false
                    onDismiss()
                }
            } message: {
                Text(String(localized: "alert_discard_message"))
            }
            .alert(String(localized: "alert_save_title"), isPresented: $showEndConfirm) {
                Button(String(localized: "common_cancel"), role: .cancel) {}
                Button(String(localized: "workout_save")) {
                    HapticHelper.medium()
                    vm.saveSession()
                    showEndConfirm = false
                }
            } message: {
                Text(String(localized: "alert_save_message"))
            }
            .overlay(alignment: .top) {
                if let text = vm.newPrBannerText {
                    Text(text)
                        .font(AppTheme.buttonLabelFont)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.memoCardPadding)
                        .padding(.vertical, AppTheme.memoSectionGap)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                        .padding(.top, AppTheme.memoSectionGap)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(AppTheme.animationOverlay(reduceMotion: reduceMotion), value: vm.newPrBannerText)
                }
            }
            .onChange(of: vm.newPrBannerText) { _, newValue in
                if let text = newValue {
                    #if os(iOS)
                    WatchSyncManager.shared.updateRest(remaining: 0, exerciseName: nil, lastPrText: text)
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        vm.newPrBannerText = nil
                    }
                }
            }
            .onChange(of: restTimer.remainingSeconds) { _, newValue in
                vm.reportRestToWatch(remaining: newValue, exerciseName: vm.currentRestExerciseName)
                if newValue <= 0 { showFullScreenRest = false }
            }
            .onReceive(NotificationCenter.default.publisher(for: WatchSyncManager.setCompleteRequestNotification)) { _ in
                vm.completeFirstIncompleteSet()
            }
            .onReceive(NotificationCenter.default.publisher(for: WatchSyncManager.weightRepsCompleteRequestNotification)) { note in
                let info = note.userInfo ?? [:]
                let w = (info["weightKg"] as? Double)
                    ?? (info["weightKg"] as? NSNumber)?.doubleValue
                let r = info["reps"] as? Int ?? (info["reps"] as? NSNumber)?.intValue
                if let w, let r, w > 0, r > 0 {
                    vm.applyWatchWeightRepsComplete(weightKg: w, reps: r)
                }
            }
            .overlay {
                if showFullScreenRest, restTimer.isResting {
                    fullScreenRestOverlay(restTimer: restTimer) {
                        showFullScreenRest = false
                    }
                    .transition(.opacity)
                }
            }
            .animation(AppTheme.animationOverlay(reduceMotion: reduceMotion), value: showFullScreenRest)
        }
    }

    private func formatRestSeconds(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func fullScreenRestOverlay(restTimer: RestTimerManager, onDismiss: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack(spacing: AppTheme.memoSectionGap + 6) {
                Text(String(localized: "workout_rest_label"))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(formatRestSeconds(restTimer.remainingSeconds))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .dynamicTypeRestCountdown()
                HStack(spacing: AppTheme.memoCardPadding) {
                    Button {
                        HapticHelper.medium()
                        restTimer.skipRest()
                        onDismiss()
                    } label: {
                        Text(String(localized: "memo_rest_skip_short"))
                            .font(AppTheme.buttonLabelFont)
                            .foregroundStyle(.white)
                            .frame(minWidth: 120, minHeight: AppTheme.touchTargetPrimary)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                    }
                    .accessibilityLabel(String(localized: "workout_skip_rest"))
                    Button {
                        HapticHelper.light()
                        restTimer.extendRest(seconds: 30)
                    } label: {
                        Text(String(localized: "workout_extend_rest_30s"))
                            .font(AppTheme.buttonLabelFont)
                            .foregroundStyle(.white)
                            .frame(minWidth: 120, minHeight: AppTheme.touchTargetPrimary)
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                    }
                    .accessibilityLabel(String(localized: "workout_extend_rest_30s"))
                }
                Button {
                    HapticHelper.light()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .accessibilityLabel(String(localized: "common_close"))
                .padding(.top, AppTheme.memoSectionGap)
            }
            .padding(AppTheme.memoCardPadding + AppTheme.memoSectionGap)
        }
    }

}

#Preview {
    WorkoutRecordView(
        draft: WorkoutSessionDraft(),
        onDismiss: {},
        onSaveSuccess: { _ in }
    )
        .modelContainer(for: [WorkoutSession.self, Exercise.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
