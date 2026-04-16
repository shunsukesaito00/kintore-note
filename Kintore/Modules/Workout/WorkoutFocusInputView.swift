// 参照アプリ風: 1種目フォーカスの記録入力画面

import SwiftUI

struct WorkoutFocusInputView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Bindable var viewModel: WorkoutRecordViewModel
    let exerciseIndex: Int
    var onNextExercise: () -> Void
    var onFinish: () -> Void
    var onAddExercise: () -> Void
    var onTimerTap: () -> Void

    @State private var editingSetIndex: Int?
    @State private var showMemoSheet = false
    @State private var memoText = ""
    @State private var weightText = ""
    @State private var repsText = ""
    @FocusState private var focused: Field?

    private enum Field: Hashable { case weight, reps }

    private var exDraft: WorkoutExerciseDraft {
        guard exerciseIndex < viewModel.draft.exercises.count else {
            return WorkoutExerciseDraft(exerciseId: UUID(), exerciseName: "")
        }
        return viewModel.draft.exercises[exerciseIndex]
    }

    private var activeIdx: Int {
        if let e = editingSetIndex, e < exDraft.sets.count { return e }
        return exDraft.sets.firstIndex { !$0.isCompleted } ?? max(exDraft.sets.count - 1, 0)
    }

    private var weightStep: Double { weightUnit == "lb" ? 5 : 2.5 }

    private var scrollBottomPadding: CGFloat {
        if focused != nil {
            return 24
        }
        return 100
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    prevRecordBanner
                    inputCard
                    actionArea
                    setHistory
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, scrollBottomPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            if focused == nil {
                bottomBar
            }
        }
        .background(AppTheme.appBackground)
        .onAppear { sync() }
        .onChange(of: weightUnit) { _, _ in sync() }
        .onChange(of: exerciseIndex) { _, _ in
            editingSetIndex = nil
            syncAfterExerciseChange()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "keyboard_toolbar_done")) { focused = nil }
            }
        }
    }

    private func sync() {
        guard exerciseIndex < viewModel.draft.exercises.count else { return }
        let idx = activeIdx
        guard idx < viewModel.draft.exercises[exerciseIndex].sets.count else { return }
        weightText = viewModel.weightString(exerciseIndex: exerciseIndex, setIndex: idx)
        repsText = viewModel.repsString(exerciseIndex: exerciseIndex, setIndex: idx)
    }

    /// 種目切替時: `editingSetIndex` をクリアした直後でも正しいセット行を参照する（`@State` 更新タイミングに依存しない）
    private func syncAfterExerciseChange() {
        guard exerciseIndex < viewModel.draft.exercises.count else { return }
        let sets = viewModel.draft.exercises[exerciseIndex].sets
        let idx = sets.firstIndex { !$0.isCompleted } ?? max(sets.count - 1, 0)
        guard idx < sets.count else { return }
        weightText = viewModel.weightString(exerciseIndex: exerciseIndex, setIndex: idx)
        repsText = viewModel.repsString(exerciseIndex: exerciseIndex, setIndex: idx)
    }

    // MARK: - Previous record

    @ViewBuilder
    private var prevRecordBanner: some View {
        if let data = viewModel.previousRecordPanelData(exerciseId: exDraft.exerciseId, weightUnit: weightUnit) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                    Text("前回: \(data.date)")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(AppTheme.secondaryText)
                ForEach(Array(data.setLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppTheme.memoRecordSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Input card

    private var inputCard: some View {
        VStack(spacing: 16) {
            setIndicator
            HStack(spacing: 24) {
                numberColumn(
                    label: String(localized: "set_header_weight"),
                    text: $weightText,
                    keyboard: .decimalPad,
                    field: .weight,
                    unit: weightUnit,
                    onMinus: { stepWeight(-1) },
                    onPlus: { stepWeight(1) }
                )
                numberColumn(
                    label: String(localized: "set_header_reps"),
                    text: $repsText,
                    keyboard: .numberPad,
                    field: .reps,
                    unit: "rep",
                    onMinus: { stepReps(-1) },
                    onPlus: { stepReps(1) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(AppTheme.memoRecordSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
    }

    private var setIndicator: some View {
        VStack(spacing: 4) {
            Text(exDraft.exerciseName)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 6) {
                Text("セット \(activeIdx + 1)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                if editingSetIndex != nil {
                    Text("(編集中)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                if let note = exDraft.sets[safe: activeIdx]?.setNote, !note.isEmpty {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }

    private func numberColumn(
        label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        field: Field,
        unit: String,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)

            TextField("0", text: text)
                .keyboardType(keyboard)
                .focused($focused, equals: field)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(minHeight: 64)
                .onChange(of: text.wrappedValue) { _, val in
                    if field == .weight {
                        viewModel.setWeight(exerciseIndex: exerciseIndex, setIndex: activeIdx, val)
                    } else {
                        viewModel.setReps(exerciseIndex: exerciseIndex, setIndex: activeIdx, val)
                    }
                }

            HStack(spacing: 14) {
                stepperCircle(icon: "minus", action: onMinus)
                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(minWidth: 28)
                stepperCircle(icon: "plus", action: onPlus)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func stepperCircle(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticHelper.light()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 34, height: 34)
                .background(Color(uiColor: .systemGray5))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action buttons

    private var actionArea: some View {
        VStack(spacing: 10) {
            Button {
                HapticHelper.light()
                memoText = exDraft.sets[safe: activeIdx]?.setNote ?? ""
                showMemoSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                    Text("メモを追加")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.accent.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showMemoSheet) { memoSheet }

            Button {
                HapticHelper.medium()
                completeSet()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                    Text("セット完了")
                        .font(.body.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            utilRow
        }
    }

    private var utilRow: some View {
        HStack(spacing: 10) {
            utilButton(icon: "timer", label: "休憩") { onTimerTap() }
            utilButton(
                icon: viewModel.isAssisted(exerciseIndex: exerciseIndex, setIndex: activeIdx) ? "hand.raised.fill" : "hand.raised",
                label: "補助"
            ) {
                let v = viewModel.isAssisted(exerciseIndex: exerciseIndex, setIndex: activeIdx)
                viewModel.setAssisted(exerciseIndex: exerciseIndex, setIndex: activeIdx, !v)
            }
            utilButton(icon: "arrow.counterclockwise", label: "前回") {
                viewModel.applyPreviousToRow(exerciseIndex: exerciseIndex, setIndex: activeIdx)
                sync()
            }
            utilButton(icon: "plus.circle", label: "セット") {
                viewModel.addSet(exerciseIndex: exerciseIndex)
            }
        }
    }

    private func utilButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticHelper.light()
            action()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Set history

    private var setHistory: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("セット")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)

            ForEach(Array(exDraft.sets.enumerated()), id: \.element.id) { i, s in
                Button {
                    HapticHelper.light()
                    editingSetIndex = i
                    sync()
                } label: {
                    setRow(i, s)
                }
                .buttonStyle(.plain)
                if i < exDraft.sets.count - 1 {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .background(AppTheme.memoRecordSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
    }

    private func setRow(_ i: Int, _ s: WorkoutSetDraft) -> some View {
        let isCurrent = i == activeIdx
        return HStack(spacing: 8) {
            Text("\(i + 1)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 24, alignment: .center)

            Group {
                if let w = s.weight, w > 0, let r = s.reps, r > 0 {
                    let wStr = displayWeight(w)
                    Text("\(wStr)\(weightUnit) × \(r)")
                } else if let w = s.weight, w > 0 {
                    Text("\(displayWeight(w))\(weightUnit)")
                } else if let r = s.reps, r > 0 {
                    Text("× \(r)")
                } else {
                    Text("—")
                }
            }
            .font(isCurrent ? .body.weight(.semibold) : .body)
            .foregroundStyle(isCurrent ? AppTheme.accent : AppTheme.primaryText)

            Spacer()

            if isCurrent {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            } else if s.isCompleted {
                Circle().fill(AppTheme.accent).frame(width: 10, height: 10)
            } else {
                Circle().stroke(AppTheme.tertiaryText, lineWidth: 1).frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(isCurrent ? AppTheme.accentSoft.opacity(0.6) : Color.clear)
        .contentShape(Rectangle())
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                HapticHelper.light()
                onNextExercise()
            } label: {
                Text("次の種目へ")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                HapticHelper.light()
                onFinish()
            } label: {
                Text("終了")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 24)
                    .frame(height: 50)
                    .background(AppTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Memo sheet

    @ViewBuilder
    private var memoSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("セットメモを入力…", text: $memoText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
            }
            .padding()
            .navigationTitle("メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { showMemoSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.setSetNote(exerciseIndex: exerciseIndex, setIndex: activeIdx, value: memoText)
                        showMemoSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Logic

    private func completeSet() {
        let idx = activeIdx
        guard exerciseIndex < viewModel.draft.exercises.count,
              idx < viewModel.draft.exercises[exerciseIndex].sets.count else { return }

        if editingSetIndex != nil {
            viewModel.setCompleted(exerciseIndex: exerciseIndex, setIndex: idx, true)
            editingSetIndex = nil
            sync()
            return
        }

        viewModel.setCompleted(exerciseIndex: exerciseIndex, setIndex: idx, true)
        if viewModel.draft.exercises[exerciseIndex].sets.allSatisfy({ $0.isCompleted }) {
            viewModel.addSet(exerciseIndex: exerciseIndex)
        }
        editingSetIndex = nil
        sync()
    }

    private func stepWeight(_ dir: Int) {
        let cur = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let next = max(0, cur + Double(dir) * weightStep)
        weightText = next > 0 ? AppFormatters.formatWeightNumber(next) : ""
        viewModel.setWeight(exerciseIndex: exerciseIndex, setIndex: activeIdx, weightText)
    }

    private func stepReps(_ dir: Int) {
        let cur = Int(repsText) ?? 0
        let next = max(0, cur + dir)
        repsText = next > 0 ? "\(next)" : ""
        viewModel.setReps(exerciseIndex: exerciseIndex, setIndex: activeIdx, repsText)
    }

    private func displayWeight(_ kg: Double) -> String {
        if weightUnit == "lb" {
            return AppFormatters.formatWeightNumber(AppFormatters.kilogramsToPounds(kg))
        }
        return AppFormatters.formatWeightNumber(kg)
    }
}

private extension Array {
    subscript(safe i: Index) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
