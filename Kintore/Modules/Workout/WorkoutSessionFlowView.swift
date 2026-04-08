// 参照アプリ風: 1種目ずつフォーカスして記録するセッションフロー

import SwiftUI
import SwiftData
import StoreKit
import UIKit

private struct FocusExerciseDetailSheet: Identifiable {
    let id: UUID
    let name: String
}

struct WorkoutSessionFlowView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let draft: WorkoutSessionDraft
    let onDismiss: () -> Void
    let onSaveSuccess: (UUID) -> Void

    @State private var viewModel: WorkoutRecordViewModel?
    @State private var currentExerciseIndex = 0
    @State private var showExercisePicker = false
    @State private var showBackConfirm = false
    @State private var showEndConfirm = false
    @State private var showFullScreenRest = false
    @State private var restTimer = RestTimerManager()
    @State private var exerciseDetailSheet: FocusExerciseDetailSheet?

    var body: some View {
        Group {
            if let vm = viewModel {
                NavigationStack {
                    focusBody(vm: vm)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(AppTheme.memoNavigationBarFill, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                        .toolbar { navToolbar(vm: vm) }
                }
                .sheet(isPresented: $showExercisePicker) {
                    ExercisePickerView(
                        onSelect: { exercise in
                            vm.addExercise(exercise)
                            currentExerciseIndex = vm.draft.exercises.count - 1
                            showExercisePicker = false
                        },
                        memoSessionStyle: true
                    )
                    .environment(\.modelContext, modelContext)
                    .standardSheetChrome()
                }
                .sheet(item: $exerciseDetailSheet) { item in
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
                        dismiss()
                        onDismiss()
                    }
                } message: { Text(String(localized: "alert_discard_message")) }
                .alert(String(localized: "alert_save_title"), isPresented: $showEndConfirm) {
                    Button(String(localized: "common_cancel"), role: .cancel) {}
                    Button(String(localized: "workout_save")) {
                        HapticHelper.medium()
                        showEndConfirm = false
                        let lastExerciseIndex = max(0, vm.draft.exercises.count - 1)
                        let isFullSessionFinish = vm.draft.exercises.count <= 1
                            || currentExerciseIndex >= lastExerciseIndex
                        WorkoutFinishInterstitialPresenter.shared.runAfterInterstitialIfNeeded(
                            shouldPresentInterstitial: isFullSessionFinish
                        ) {
                            vm.saveSession()
                        }
                    }
                } message: { Text(String(localized: "alert_save_message")) }
                .overlay(alignment: .top) { prBanner(vm: vm) }
                .overlay { restOverlay(vm: vm) }
                .animation(AppTheme.animationOverlay(reduceMotion: reduceMotion), value: showFullScreenRest)
                .onChange(of: vm.newPrBannerText) { _, newValue in
                    if let text = newValue {
                        #if os(iOS)
                        WatchSyncManager.shared.updateRest(remaining: 0, exerciseName: nil, lastPrText: text)
                        #endif
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { vm.newPrBannerText = nil }
                    }
                }
                .onAppear {
                    restTimer.restoreFromUserDefaults()
                    vm.reportRestToWatch(remaining: restTimer.remainingSeconds, exerciseName: vm.currentRestExerciseName)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    restTimer.restoreFromUserDefaults()
                }
                .onChange(of: restTimer.remainingSeconds) { _, sec in
                    vm.reportRestToWatch(remaining: sec, exerciseName: vm.currentRestExerciseName)
                    if sec <= 0 { showFullScreenRest = false }
                }
                .onReceive(NotificationCenter.default.publisher(for: WatchSyncManager.setCompleteRequestNotification)) { _ in
                    vm.completeFirstIncompleteSet()
                }
                .onReceive(NotificationCenter.default.publisher(for: WatchSyncManager.weightRepsCompleteRequestNotification)) { note in
                    let info = note.userInfo ?? [:]
                    let w = (info["weightKg"] as? Double) ?? (info["weightKg"] as? NSNumber)?.doubleValue
                    let r = info["reps"] as? Int ?? (info["reps"] as? NSNumber)?.intValue
                    if let w, let r, w > 0, r > 0 { vm.applyWatchWeightRepsComplete(weightKg: w, reps: r) }
                }
            } else {
                ProgressView(String(localized: "home_loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { createVM() }
            }
        }
    }

    // MARK: - Focus body

    @ViewBuilder
    private func focusBody(vm: WorkoutRecordViewModel) -> some View {
        if vm.draft.exercises.isEmpty {
            emptyState
        } else {
            let idx = min(currentExerciseIndex, vm.draft.exercises.count - 1)
            WorkoutFocusInputView(
                viewModel: vm,
                exerciseIndex: idx,
                onNextExercise: {
                    if idx < vm.draft.exercises.count - 1 {
                        currentExerciseIndex = idx + 1
                    } else {
                        showExercisePicker = true
                    }
                },
                onFinish: { showEndConfirm = true },
                onAddExercise: { showExercisePicker = true },
                onTimerTap: {
                    vm.startManualRestForExercise(exerciseIndex: idx)
                    showFullScreenRest = true
                }
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.memoSectionGap) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft.opacity(0.35))
                    .frame(width: 112, height: 112)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 52))
                    .foregroundStyle(AppTheme.accent.opacity(0.55))
                    .symbolRenderingMode(.hierarchical)
            }
            Text(String(localized: "session_hub_empty_hint"))
                .font(AppTheme.bodySecondaryFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
            Button {
                HapticHelper.light()
                showExercisePicker = true
            } label: {
                Text("種目を追加")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .frame(height: 50)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.appBackground)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func navToolbar(vm: WorkoutRecordViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                HapticHelper.light()
                if vm.hasMeaningfulInput() { showBackConfirm = true }
                else { dismiss(); onDismiss() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.memoNavBarForeground)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.25)))
            }
            .accessibilityLabel(String(localized: "workout_nav_back_a11y"))
        }
        ToolbarItem(placement: .principal) {
            exerciseTitle(vm: vm)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if vm.draft.exercises.count > 1 {
                exercisePageButtons(vm: vm)
            }
            MemoNavBarWeightUnitPicker(selection: $weightUnit)
            Button {
                HapticHelper.light()
                showExercisePicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.memoNavBarForeground)
            }
            .accessibilityLabel(String(localized: "workout_start_add_exercise"))
        }
    }

    @ViewBuilder
    private func exerciseTitle(vm: WorkoutRecordViewModel) -> some View {
        if !vm.draft.exercises.isEmpty {
            let idx = min(currentExerciseIndex, vm.draft.exercises.count - 1)
            Button {
                let ex = vm.draft.exercises[idx]
                exerciseDetailSheet = FocusExerciseDetailSheet(id: ex.exerciseId, name: ex.exerciseName)
            } label: {
                Text(vm.draft.exercises[idx].exerciseName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.memoNavBarForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        } else {
            Text(String(localized: "workout_nav_select_exercise"))
                .font(.body.weight(.bold))
                .foregroundStyle(AppTheme.memoNavBarForeground)
        }
    }

    @ViewBuilder
    private func exercisePageButtons(vm: WorkoutRecordViewModel) -> some View {
        let idx = min(currentExerciseIndex, vm.draft.exercises.count - 1)
        HStack(spacing: 2) {
            Button {
                HapticHelper.light()
                if idx > 0 { currentExerciseIndex = idx - 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(idx > 0 ? AppTheme.memoNavBarForeground : AppTheme.memoNavBarForeground.opacity(0.3))
                    .frame(width: 26, height: 26)
            }
            .disabled(idx <= 0)
            Text("\(idx + 1)/\(vm.draft.exercises.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.memoNavBarForeground)
                .frame(minWidth: 28)
            Button {
                HapticHelper.light()
                if idx < vm.draft.exercises.count - 1 { currentExerciseIndex = idx + 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(idx < vm.draft.exercises.count - 1 ? AppTheme.memoNavBarForeground : AppTheme.memoNavBarForeground.opacity(0.3))
                    .frame(width: 26, height: 26)
            }
            .disabled(idx >= vm.draft.exercises.count - 1)
        }
    }

    // MARK: - PR banner & rest overlay

    @ViewBuilder
    private func prBanner(vm: WorkoutRecordViewModel) -> some View {
        if let text = vm.newPrBannerText {
            Text(text)
                .font(AppTheme.buttonLabelFont)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.memoCardPadding)
                .padding(.vertical, AppTheme.memoSectionGap)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                .padding(.top, AppTheme.memoSectionGap)
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                .animation(AppTheme.animationOverlay(reduceMotion: reduceMotion), value: vm.newPrBannerText)
        }
    }

    @ViewBuilder
    private func restOverlay(vm: WorkoutRecordViewModel) -> some View {
        if showFullScreenRest, restTimer.isResting {
            ZStack {
                Color.black.opacity(0.85).ignoresSafeArea()
                    .onTapGesture { showFullScreenRest = false }
                VStack(spacing: 20) {
                    Text(String(localized: "workout_rest_label"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatRest(restTimer.remainingSeconds))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .dynamicTypeRestCountdown()
                    HStack(spacing: 16) {
                        Button {
                            HapticHelper.medium()
                            restTimer.skipRest()
                            showFullScreenRest = false
                        } label: {
                            Text(String(localized: "memo_rest_skip_short"))
                                .font(AppTheme.buttonLabelFont).foregroundStyle(.white)
                                .frame(minWidth: 120, minHeight: 50)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        Button {
                            HapticHelper.light()
                            restTimer.extendRest(seconds: 30)
                        } label: {
                            Text(String(localized: "workout_extend_rest_30s"))
                                .font(AppTheme.buttonLabelFont).foregroundStyle(.white)
                                .frame(minWidth: 120, minHeight: 50)
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    Button { showFullScreenRest = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title).foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 8)
                }
            }
            .transition(.opacity)
        }
    }

    private func formatRest(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: - Init

    private func createVM() {
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
        v.onSaveSuccess = { id in HapticHelper.success(); onSaveSuccess(id) }
        v.onRequestReview = { requestReview() }
        restTimer.restoreFromUserDefaults()
        v.loadPreviousRecords()
        viewModel = v
    }
}
