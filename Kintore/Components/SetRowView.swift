// File: Components/SetRowView.swift
// 記録画面セット行: 列幅は AppTheme とセッション詳細の表と一致。

import SwiftUI

struct SetRowView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @AppStorage(AppTheme.simpleSetInputStorageKey) private var simpleSetInputMode: Bool = false
    let exerciseKind: ExerciseKind
    let orderIndex: Int
    @Binding var weight: String
    @Binding var reps: String
    @Binding var setType: String
    @Binding var rpe: Int?
    @Binding var isAssisted: Bool
    @Binding var isCompleted: Bool
    let canApplyPrevious: Bool
    let onApplyPrevious: () -> Void
    var canCopyFromAbove: Bool = false
    var onCopyFromAbove: (() -> Void)?
    var onDelete: (() -> Void)?
    /// 指定時は `@AppStorage` より優先（セッションフローで kg 固定するため）
    var weightUnitDisplay: String? = nil
    /// MEMO 風: 下線のみ・プレースホルダ「重さ」「回数」
    var memoFlowInputStyle: Bool = false
    /// 有酸素の入力種別（`Exercise.cardioInputStyle`）。トレッドミル時は `treadmillDuration` も渡す。
    var cardioInputStyle: String? = nil
    var treadmillDuration: Binding<String>? = nil
    @FocusState private var focusedField: Field?

    private enum Field {
        case weight
        case reps
        case duration
    }

    private var isTreadmillCardioRow: Bool {
        exerciseKind == .cardio && cardioInputStyle == CardioInputStyle.treadmill.rawValue
    }

    private var useMemoTreadmillGrid: Bool {
        memoFlowInputStyle && isTreadmillCardioRow && treadmillDuration != nil
    }

    private var displayWeightUnit: String {
        weightUnitDisplay ?? weightUnit
    }

    private var useMemoStrengthGrid: Bool {
        memoFlowInputStyle && (exerciseKind == .strength || exerciseKind == .weightedBodyweight)
    }

    /// MEMO 筋力: 種別を列で出す（シンプル入力モードでは … のみ）
    private var showInlineSetType: Bool {
        memoFlowInputStyle && !simpleSetInputMode && (exerciseKind == .strength || exerciseKind == .weightedBodyweight)
    }

    private var memoActionClusterEffectiveWidth: CGFloat {
        showInlineSetType ? AppTheme.memoFlowActionClusterWidthNarrow : AppTheme.memoFlowActionClusterWidth
    }

    /// 入力文字列を内部 kg に正規化（lb 表示時は lb→kg）
    private var parsedWeightKg: Double? {
        guard let d = Double(weight.replacingOccurrences(of: ",", with: ".")) else { return nil }
        let kg: Double
        if displayWeightUnit == "lb" {
            kg = AppFormatters.poundsToKilograms(d)
        } else {
            kg = d
        }
        return kg > 0 ? kg : nil
    }

    private var memoSessionAccent: Color {
        AppTheme.accent
    }

    private func setIndexAccessibilityLabel() -> String {
        String(format: String(localized: "set_a11y_set_index_fmt"), locale: .current, orderIndex + 1)
    }

    private func memoAlternateWeightLine(kg: Double) -> String {
        if displayWeightUnit == "kg" {
            return String(format: "%.1f lb", AppFormatters.kilogramsToPounds(kg))
        }
        return String(format: "%.1f kg", kg)
    }

    private func memoInputCell() -> some View {
        RoundedRectangle(cornerRadius: AppTheme.memoSetInputCellCornerRadius, style: .continuous)
            .fill(AppTheme.memoInputCellFill)
    }

    @ViewBuilder
    private func memoFlowFieldBackground() -> some View {
        if memoFlowInputStyle {
            Color.clear
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppTheme.primaryText.opacity(AppTheme.memoFlowHairlineOpacity))
                        .frame(height: 0.5)
                }
        } else {
            memoInputCell()
        }
    }

    /// MEMO グリッドの入力セル（下線のみから枠付きへ：フォーカスでアクセント縁）
    private func memoFieldChrome(isFocused: Bool) -> some View {
        RoundedRectangle(cornerRadius: AppTheme.memoSetFieldCornerRadius, style: .continuous)
            .fill(AppTheme.memoInputCellFill)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.memoSetFieldCornerRadius, style: .continuous)
                    .stroke(isFocused ? AppTheme.accent : Color(uiColor: .separator).opacity(0.55), lineWidth: isFocused ? 1.5 : 0.5)
            )
    }

    var body: some View {
        Group {
            if useMemoStrengthGrid {
                memoStrengthTableRow
            } else if useMemoTreadmillGrid {
                memoTreadmillCardioTableRow
            } else {
                legacySetRow
            }
        }
        .padding(.vertical, memoFlowInputStyle ? 0 : 8)
        .padding(.horizontal, memoFlowInputStyle ? AppTheme.memoSetRowPaddingH : 8)
        .background(isCompleted ? AppTheme.accentSoft.opacity(0.55) : Color.clear)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "keyboard_toolbar_done")) {
                    focusedField = nil
                }
            }
        }
    }

    // MARK: - MEMO 風（筋力）固定列

    private var memoStrengthTableRow: some View {
        HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
            Text("\(orderIndex + 1)")
                .font(AppTheme.memoFlowSetIndexFont)
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: AppTheme.memoSetIndexColumnWidth, alignment: .center)
                .frame(minHeight: AppTheme.memoStrengthRowMinHeight)
                .accessibilityLabel(setIndexAccessibilityLabel())

            HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
                memoStrengthWeightColumn
                memoStrengthRepsColumn
                if showInlineSetType {
                    memoSetTypeColumn
                }
            }
            .frame(maxWidth: .infinity)

            memoActionCluster

            assistColumn
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: AppTheme.memoStrengthRowMinHeight)
    }

    // MARK: - MEMO 風・トレッドミル有酸素（傾斜・速度・時間）

    private var memoTreadmillCardioTableRow: some View {
        Group {
            if let dur = treadmillDuration {
                HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
                    Text("\(orderIndex + 1)")
                        .font(AppTheme.memoFlowSetIndexFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: AppTheme.memoSetIndexColumnWidth, alignment: .center)
                        .frame(minHeight: AppTheme.memoStrengthRowMinHeight)
                        .accessibilityLabel(setIndexAccessibilityLabel())

                    HStack(alignment: .center, spacing: AppTheme.memoFlowTableColumnSpacing) {
                        memoTreadmillInputColumn(
                            text: $weight,
                            unit: "%",
                            keyboard: .decimalPad,
                            focusTag: .weight,
                            onSubmit: { focusedField = .reps },
                            accessibilityLabel: String(format: String(localized: "set_a11y_treadmill_incline_fmt"), orderIndex + 1)
                        )
                        memoTreadmillInputColumn(
                            text: $reps,
                            unit: String(localized: "unit_kmh"),
                            keyboard: .decimalPad,
                            focusTag: .reps,
                            onSubmit: { focusedField = .duration },
                            accessibilityLabel: String(format: String(localized: "set_a11y_treadmill_speed_fmt"), orderIndex + 1)
                        )
                        memoTreadmillInputColumn(
                            text: dur,
                            unit: String(localized: "unit_seconds"),
                            keyboard: .numberPad,
                            focusTag: .duration,
                            onSubmit: { focusedField = nil },
                            accessibilityLabel: String(format: String(localized: "set_a11y_treadmill_duration_fmt"), orderIndex + 1)
                        )
                    }
                    .frame(maxWidth: .infinity)

                    memoActionCluster

                    assistColumn
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: AppTheme.memoStrengthRowMinHeight)
            }
        }
    }

    private func memoTreadmillInputColumn(
        text: Binding<String>,
        unit: String,
        keyboard: UIKeyboardType,
        focusTag: Field,
        onSubmit: @escaping () -> Void,
        accessibilityLabel: String
    ) -> some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(spacing: 2) {
                TextField("", text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(focusTag == .duration ? .done : .next)
                    .focused($focusedField, equals: focusTag)
                    .onSubmit { onSubmit() }
                    .font(AppTheme.memoStrengthNumericInputFont)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(accessibilityLabel)
                if !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        HapticHelper.light()
                        text.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "set_input_clear_reps_a11y"))
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 2)
            .background(memoFieldChrome(isFocused: focusedField == focusTag))
            .frame(minHeight: AppTheme.memoStrengthRowMinHeight)
            .frame(maxWidth: .infinity)

            Text(unit)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.tertiaryText)
                .fixedSize()
        }
        .frame(maxWidth: .infinity)
    }


    private var memoSetTypeColumn: some View {
        Menu {
            Section {
                ForEach(SetTypeTag.allCases, id: \.rawValue) { tag in
                    Button {
                        setType = tag.rawValue
                    } label: {
                        HStack(spacing: 8) {
                            Text(tag.menuLineTitle)
                            if SetTypeTag(rawValue: setType) == tag {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Text(SetTypeTag(rawValue: setType).map { $0.abbreviation } ?? "—")
                .font(AppTheme.memoSetTypeAbbreviationFont)
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .padding(.horizontal, 2)
                .background(memoFieldChrome(isFocused: false))
                .frame(minHeight: AppTheme.memoStrengthRowMinHeight)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(String(localized: "set_a11y_set_type_column"))
    }

    @ViewBuilder
    private var memoActionCluster: some View {
        HStack(spacing: 0) {
            if canCopyFromAbove, let onCopyFromAbove = onCopyFromAbove {
                memoAccentCircleIconButton(systemName: "arrow.up.to.line", enabled: true) {
                    HapticHelper.light()
                    onCopyFromAbove()
                }
                .frame(width: AppTheme.memoFlowCopyColumnWidth, height: AppTheme.memoStrengthRowMinHeight)
                .accessibilityLabel(String(localized: "set_a11y_copy_from_above"))
            } else {
                Color.clear.frame(width: AppTheme.memoFlowCopyColumnWidth, height: 1)
            }

            if !simpleSetInputMode {
                if showInlineSetType {
                    Color.clear.frame(width: 0, height: 1)
                } else {
                    Menu {
                        setDetailMenuContent
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                    .buttonStyle(.plain)
                    .frame(width: AppTheme.memoFlowIconColumnWidth, height: AppTheme.memoStrengthRowMinHeight)
                    .accessibilityLabel(String(localized: "set_a11y_set_detail_menu"))
                }
            } else {
                Color.clear.frame(width: AppTheme.memoFlowIconColumnWidth, height: 1)
            }

            memoAccentCircleIconButton(systemName: "arrow.down.to.line", enabled: canApplyPrevious) {
                HapticHelper.light()
                onApplyPrevious()
            }
            .disabled(!canApplyPrevious)
            .frame(width: AppTheme.memoFlowIconColumnWidth, height: AppTheme.memoStrengthRowMinHeight)
            .accessibilityLabel(String(localized: "set_a11y_apply_previous_record"))

            if let onDelete = onDelete {
                Button {
                    HapticHelper.light()
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
                .frame(width: AppTheme.memoFlowIconColumnWidth, height: AppTheme.memoStrengthRowMinHeight)
                .accessibilityLabel(String(localized: "set_a11y_delete_this_set"))
            } else {
                Color.clear.frame(width: AppTheme.memoFlowIconColumnWidth, height: 1)
            }
        }
        .frame(width: memoActionClusterEffectiveWidth, alignment: .leading)
    }

    /// 参照寄せ: 青い円に白い SF Symbol
    private func memoAccentCircleIconButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(enabled ? AppTheme.accent : Color(uiColor: .tertiarySystemFill)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var assistColumn: some View {
        Group {
            if exerciseKind == .strength || exerciseKind == .weightedBodyweight {
                Button {
                    HapticHelper.light()
                    isAssisted.toggle()
                } label: {
                    Image(systemName: isAssisted ? "hand.raised.fill" : "hand.raised")
                        .font(.system(size: 17))
                        .foregroundStyle(isAssisted ? memoSessionAccent : Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
                .frame(width: AppTheme.setTableAssistColumnWidth, height: AppTheme.memoStrengthRowMinHeight)
                .accessibilityLabel(isAssisted ? String(localized: "set_a11y_assist_enabled_hint") : String(localized: "set_a11y_assist_disabled_hint"))
            }
        }
    }

    @ViewBuilder
    private var setDetailMenuContent: some View {
        Section(String(localized: "set_menu_section_kind")) {
            ForEach(SetTypeTag.allCases, id: \.rawValue) { tag in
                Button {
                    setType = tag.rawValue
                } label: {
                    HStack(spacing: 8) {
                        Text(tag.menuLineTitle)
                        if SetTypeTag(rawValue: setType) == tag {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        Section(String(localized: "set_menu_section_assist")) {
            Button {
                isAssisted = true
            } label: {
                HStack(spacing: 8) {
                    Text(String(localized: "set_menu_spotter_assisted"))
                    if isAssisted {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button {
                isAssisted = false
            } label: {
                HStack(spacing: 8) {
                    Text(String(localized: "set_menu_no_assist_help"))
                    if !isAssisted {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    // MARK: - 従来レイアウト（トレッドミル3列）

    private func legacyTreadmillTripleColumns(duration: Binding<String>) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            legacyTreadmillField(
                text: $weight,
                subscriptLabel: "%",
                keyboard: .decimalPad,
                focusTag: .weight,
                onSubmit: { focusedField = .reps }
            )
            legacyTreadmillField(
                text: $reps,
                subscriptLabel: String(localized: "unit_kmh"),
                keyboard: .decimalPad,
                focusTag: .reps,
                onSubmit: { focusedField = .duration }
            )
            legacyTreadmillField(
                text: duration,
                subscriptLabel: String(localized: "unit_seconds"),
                keyboard: .numberPad,
                focusTag: .duration,
                onSubmit: { focusedField = nil }
            )
        }
    }

    private func legacyTreadmillField(
        text: Binding<String>,
        subscriptLabel: String,
        keyboard: UIKeyboardType,
        focusTag: Field,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 2) {
            TextField(
                "",
                text: text,
                prompt: Text("—")
                    .foregroundStyle(AppTheme.tertiaryText)
            )
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .submitLabel(focusTag == .duration ? .done : .next)
            .focused($focusedField, equals: focusTag)
            .onSubmit { onSubmit() }
            .font(memoFlowInputStyle ? AppTheme.memoStrengthNumericInputFont : AppTheme.setInputNumericFont)
            .multilineTextAlignment(.center)
            .padding(.vertical, memoFlowInputStyle ? 6 : 6)
            .padding(.horizontal, memoFlowInputStyle ? 3 : 4)
            .background(memoFlowFieldBackground())
            .frame(minHeight: memoFlowInputStyle ? AppTheme.memoStrengthGridInputMinHeight : 34)
            .frame(maxWidth: .infinity)
            Text(subscriptLabel)
                .font(AppTheme.weightUnitSubscriptFont)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
        }
        .frame(width: AppTheme.setTableTreadmillFieldWidth)
    }

    // MARK: - 従来レイアウト

    private var legacySetRow: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMD) {
            Text("\(orderIndex + 1)")
                .font(AppTheme.setIndexLabelFont)
                .foregroundStyle(memoFlowInputStyle ? AppTheme.primaryText : AppTheme.secondaryText)
                .fontWeight(memoFlowInputStyle ? .bold : .regular)
                .frame(width: AppTheme.setTableSetColumnWidth, alignment: .center)
                .accessibilityLabel(setIndexAccessibilityLabel())

            if isTreadmillCardioRow, !memoFlowInputStyle, let dur = treadmillDuration {
                legacyTreadmillTripleColumns(duration: dur)
            } else {
                firstInputColumn

                secondInputColumn
            }

            Spacer(minLength: 0)

            if canCopyFromAbove, let onCopyFromAbove = onCopyFromAbove {
                Button {
                    HapticHelper.light()
                    onCopyFromAbove()
                } label: {
                    Image(systemName: "arrow.up.to.line.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(memoFlowInputStyle ? memoSessionAccent : AppTheme.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 40)
                .accessibilityLabel(String(localized: "set_a11y_copy_from_above"))
            }

            if exerciseKind == .strength || exerciseKind == .weightedBodyweight {
                if simpleSetInputMode {
                    Button {
                        HapticHelper.light()
                        isAssisted.toggle()
                    } label: {
                        Image(systemName: isAssisted ? "hand.raised.fill" : "hand.raised")
                            .font(.system(size: 20))
                            .foregroundStyle(isAssisted ? memoSessionAccent : Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 28, height: 40)
                    .accessibilityLabel(isAssisted ? String(localized: "set_a11y_assist_enabled_hint") : String(localized: "set_a11y_assist_disabled_hint"))
                }

                if !simpleSetInputMode {
                    Menu {
                        setDetailMenuContent
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                            .frame(width: 28, height: 40)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(String(localized: "set_a11y_set_detail_menu"))
                }
            } else if isTreadmillCardioRow, !simpleSetInputMode {
                Menu {
                    setDetailMenuContent
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .frame(width: 28, height: 40)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(String(localized: "set_a11y_set_detail_menu"))
            }

            Button {
                HapticHelper.light()
                onApplyPrevious()
            } label: {
                Image(systemName: "arrow.down.to.line.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(canApplyPrevious ? (memoFlowInputStyle ? memoSessionAccent : AppTheme.accent) : Color(uiColor: .tertiaryLabel))
            }
            .buttonStyle(.plain)
            .disabled(!canApplyPrevious)
            .frame(width: 32, height: 40)
            .accessibilityLabel(String(localized: "set_a11y_apply_previous_record"))

            if let onDelete = onDelete {
                Button {
                    HapticHelper.light()
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 40)
                .accessibilityLabel(String(localized: "set_a11y_delete_this_set"))
            }

            Toggle("", isOn: $isCompleted)
                .labelsHidden()
                .toggleStyle(.button)
                .tint(AppTheme.accent)
                .onChange(of: isCompleted) { _, newValue in
                    if newValue {
                        HapticHelper.light()
                    }
                }
                .frame(width: 40, height: 40)
                .accessibilityLabel(String(format: String(localized: "set_a11y_completion_toggle_fmt"), locale: .current, orderIndex + 1))
                .accessibilityValue(isCompleted ? String(localized: "set_a11y_completion_done") : String(localized: "set_a11y_completion_pending"))
                .accessibilityHint(String(localized: "set_a11y_completion_toggle_hint"))
        }
    }

    @ViewBuilder
    private var firstInputColumn: some View {
        Group {
            if useMemoStrengthGrid {
                memoStrengthWeightColumn
            } else {
                legacyFirstInputColumn
                    .frame(width: AppTheme.setTableWeightColumnWidth, alignment: .center)
            }
        }
    }

    /// MEMO 筋力: 数値のみの入力枠＋右側に単位（グレー）
    private var memoStrengthWeightColumn: some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(spacing: 2) {
                TextField("", text: $weight)
                    .keyboardType(firstKeyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(exerciseKind == .time ? .done : .next)
                    .focused($focusedField, equals: .weight)
                    .onSubmit {
                        if exerciseKind == .cardio || exerciseKind == .strength || exerciseKind == .weightedBodyweight {
                            focusedField = .reps
                        } else {
                            focusedField = nil
                        }
                    }
                    .font(AppTheme.memoStrengthNumericInputFont)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(weightFieldAccessibilityLabel)
                if !weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        HapticHelper.light()
                        weight = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "set_input_clear_weight_a11y"))
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 2)
            .background(memoFieldChrome(isFocused: focusedField == .weight))
            .frame(minHeight: AppTheme.memoStrengthRowMinHeight)
            .frame(maxWidth: .infinity)

            Text(displayWeightUnit)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.tertiaryText)
                .fixedSize()
        }
        .frame(maxWidth: .infinity)
    }

    /// 重量欄の VoiceOver（換算はラベルに含める）
    private var weightFieldAccessibilityLabel: String {
        var base = firstAccessibilityLabel
        if let kg = parsedWeightKg {
            base += "、\(memoAlternateWeightLine(kg: kg))"
        }
        return base
    }

    private var legacyFirstInputColumn: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                TextField(
                    "",
                    text: $weight,
                    prompt: Text(memoFlowInputStyle ? String(localized: "set_input_weight_placeholder") : "—")
                        .foregroundStyle(AppTheme.tertiaryText)
                )
                    .keyboardType(firstKeyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(exerciseKind == .time ? .done : .next)
                    .focused($focusedField, equals: .weight)
                    .onSubmit {
                        if exerciseKind == .cardio || exerciseKind == .strength || exerciseKind == .weightedBodyweight {
                            focusedField = .reps
                        } else {
                            focusedField = nil
                        }
                    }
                    .font(memoFlowInputStyle ? AppTheme.memoStrengthNumericInputFont : AppTheme.setInputNumericFont)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, memoFlowInputStyle ? 6 : 6)
                    .padding(.horizontal, memoFlowInputStyle ? 3 : 4)
                    .background(memoFlowFieldBackground())
                    .frame(minHeight: memoFlowInputStyle ? AppTheme.memoStrengthGridInputMinHeight : 34)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(firstAccessibilityLabel)
            }
            Text(firstSubscript)
                .font(AppTheme.weightUnitSubscriptFont)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var secondInputColumn: some View {
        Group {
            if useMemoStrengthGrid {
                memoStrengthRepsColumn
            } else {
                legacySecondInputColumn
                    .frame(width: AppTheme.setTableRepsColumnWidth, alignment: .center)
            }
        }
    }

    private var memoStrengthRepsColumn: some View {
        Group {
            if exerciseKind == .time {
                Text("—")
                    .font(AppTheme.setInputNumericFont)
                    .foregroundStyle(AppTheme.tertiaryText)
                    .frame(minHeight: AppTheme.memoStrengthRowMinHeight)
                    .frame(maxWidth: .infinity)
            } else {
                HStack(alignment: .center, spacing: 4) {
                    HStack(spacing: 2) {
                        TextField("", text: $reps)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .reps)
                            .onSubmit { focusedField = nil }
                            .font(AppTheme.memoStrengthNumericInputFont)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.88)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(secondAccessibilityLabel)
                        if !reps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                HapticHelper.light()
                                reps = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "set_input_clear_reps_a11y"))
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 2)
                    .background(memoFieldChrome(isFocused: focusedField == .reps))
                    .frame(minHeight: AppTheme.memoStrengthRowMinHeight)
                    .frame(maxWidth: .infinity)

                    Text(secondSubscript)
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.tertiaryText)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var legacySecondInputColumn: some View {
        VStack(spacing: 2) {
            if exerciseKind == .time {
                Text("—")
                    .font(AppTheme.setInputNumericFont)
                    .foregroundStyle(AppTheme.tertiaryText)
                    .frame(minHeight: 34)
            } else {
                HStack(spacing: 2) {
                    TextField(
                        "",
                        text: $reps,
                        prompt: Text(memoFlowInputStyle ? String(localized: "set_input_reps_placeholder") : "—")
                            .foregroundStyle(AppTheme.tertiaryText)
                    )
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .reps)
                        .onSubmit { focusedField = nil }
                        .font(memoFlowInputStyle ? AppTheme.memoStrengthNumericInputFont : AppTheme.setInputNumericFont)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, memoFlowInputStyle ? 6 : 6)
                        .padding(.horizontal, memoFlowInputStyle ? 3 : 4)
                        .background(memoFlowFieldBackground())
                        .frame(minHeight: memoFlowInputStyle ? AppTheme.memoStrengthGridInputMinHeight : 34)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(secondAccessibilityLabel)
                }
            }
            Text(secondSubscript)
                .font(AppTheme.weightUnitSubscriptFont)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
        }
    }

    private var firstKeyboardType: UIKeyboardType {
        switch exerciseKind {
        case .strength, .weightedBodyweight, .cardio: return .decimalPad
        case .time: return .numberPad
        }
    }

    private var firstSubscript: String {
        switch exerciseKind {
        case .strength, .weightedBodyweight: return displayWeightUnit
        case .time: return String(localized: "unit_seconds")
        case .cardio: return String(localized: "unit_km")
        }
    }

    private var secondSubscript: String {
        switch exerciseKind {
        case .strength, .weightedBodyweight: return String(localized: "set_input_subscript_reps")
        case .time: return ""
        case .cardio: return String(localized: "unit_seconds")
        }
    }

    private var firstAccessibilityLabel: String {
        let n = orderIndex + 1
        switch exerciseKind {
        case .strength, .weightedBodyweight:
            return String(format: String(localized: "set_a11y_strength_weight_fmt"), n)
        case .time:
            return String(format: String(localized: "set_a11y_time_seconds_fmt"), n)
        case .cardio:
            return String(format: String(localized: "set_a11y_cardio_distance_fmt"), n)
        }
    }

    private var secondAccessibilityLabel: String {
        let n = orderIndex + 1
        switch exerciseKind {
        case .strength, .weightedBodyweight:
            return String(format: String(localized: "set_a11y_strength_reps_fmt"), n)
        case .time: return ""
        case .cardio:
            return String(format: String(localized: "set_a11y_cardio_seconds_fmt"), n)
        }
    }
}

#Preview {
    struct Holder: View {
        @State var w = "40"
        @State var r = "10"
        @State var st = SetTypeTag.normal.rawValue
        @State var rp: Int? = nil
        @State var asst = false
        @State var done = false
        var body: some View {
            VStack(spacing: 0) {
                SetTableHeaderRow(exerciseKind: .strength, weightUnit: "kg")
                SetRowView(
                    exerciseKind: .strength,
                    orderIndex: 0,
                    weight: $w,
                    reps: $r,
                    setType: $st,
                    rpe: $rp,
                    isAssisted: $asst,
                    isCompleted: $done,
                    canApplyPrevious: true,
                    onApplyPrevious: {},
                    canCopyFromAbove: false,
                    onCopyFromAbove: nil,
                    onDelete: {}
                )
            }
            .background(AppTheme.memoRecordSurface)
            .padding()
        }
    }
    return Holder()
}
