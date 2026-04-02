// File: Modules/Exercise/ExercisePickerView.swift

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Exercise) -> Void
    /// セッションフロー向け: 部位カードレイアウト
    var memoSessionStyle: Bool = false

    @State private var searchText = ""
    @State private var viewModel: ExercisePickerViewModel?
    @State private var showCreateExercise = false
    @State private var createInitialBodyPart: String?
    /// 部位ごとに「すべて表示」で全件開く
    @State private var expandedBodyParts: Set<String> = []
    /// nil / 空 = 器具フィルタなし（`equipmentTag` 完全一致）
    @State private var equipmentFilterTag: String?

    private let previewLimit = 3

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if memoSessionStyle {
                        memoSessionContent(vm: vm)
                    } else {
                        legacyListContent(vm: vm)
                    }
                } else {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(AppTheme.appBackground)
            .navigationTitle(String(localized: "workout_nav_select_exercise"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.memoNavigationBarFill, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: String(localized: "picker_search_prompt"))
            .toolbar {
                if memoSessionStyle {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.memoNavBarForeground)
                        }
                        .accessibilityLabel(String(localized: "workout_nav_back_a11y"))
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "common_cancel")) { dismiss() }
                            .foregroundStyle(AppTheme.memoNavBarForeground)
                    }
                }
            }
            .sheet(isPresented: $showCreateExercise) {
                CreateExerciseView(initialBodyPart: createInitialBodyPart) { name, bodyPart, equipment, kind in
                    guard let vm = viewModel else { return }
                    if let newEx = try? vm.insertNewExercise(name: name, bodyPart: bodyPart, equipment: equipment, exerciseKind: kind) {
                        onSelect(newEx)
                        dismiss()
                    }
                    showCreateExercise = false
                    createInitialBodyPart = nil
                }
                .standardSheetChrome()
            }
            .onAppear { createViewModelOnce() }
        }
    }

    private var pillAddButton: some View {
        Button {
            HapticHelper.light()
            createInitialBodyPart = nil
            showCreateExercise = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption.weight(.semibold))
                Text(String(localized: "workout_start_add_body_part_exercise"))
                    .font(AppTheme.captionTypographyFont.weight(.semibold))
            }
            .foregroundStyle(AppTheme.primaryText)
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func memoSessionContent(vm: ExercisePickerViewModel) -> some View {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameFiltered = keyword.isEmpty
            ? vm.exercises
            : vm.exercises.filter { ExerciseSearch.matches($0, keyword: keyword) }
        let base = applyEquipmentFilter(nameFiltered)
        let groups = vm.groupedExercises(filtered: base)
        let equipTags = sortedEquipmentTags(from: vm.exercises)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.memoSectionGap) {
                if !equipTags.isEmpty {
                    equipmentFilterChipsRow(tags: equipTags)
                }
                HStack {
                    Spacer()
                    pillAddButton
                }
                .padding(.bottom, AppTheme.spacingXS)

                ForEach(groups, id: \.bodyPart) { group in
                    bodyPartCard(group: group, vm: vm)
                }
            }
            .padding(.horizontal, AppTheme.memoCardPadding)
            .padding(.vertical, AppTheme.memoSectionGap)
        }
    }

    private func bodyPartCard(group: (bodyPart: String, exercises: [Exercise]), vm: ExercisePickerViewModel) -> some View {
        let partKey = group.bodyPart
        let headerTitle = ExercisePickerViewModel.displayBodyPartLabel(for: partKey)
        let latest = vm.latestDate(in: group.exercises)
        let subtitle = relativeSubtitle(lastActivity: latest)
        let isExpanded = expandedBodyParts.contains(partKey)
        let list = isExpanded ? group.exercises : Array(group.exercises.prefix(previewLimit))
        let hasMore = group.exercises.count > previewLimit

        return VStack(alignment: .leading, spacing: 0) {
            Text("\(headerTitle) - \(subtitle)")
                .font(AppTheme.subheadlineFont.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, AppTheme.memoPickerExerciseRowPaddingV)
                .padding(.horizontal, AppTheme.memoCardPadding)
                .background(AppTheme.memoNavigationBarFill)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: AppTheme.cardCornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: AppTheme.cardCornerRadius
                    )
                )

            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.element.id) { index, exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(AppTheme.bodySecondaryFont.weight(.medium))
                                    .foregroundStyle(AppTheme.primaryText)
                                let kind = ExerciseKind(stored: exercise.exerciseKind)
                                if kind != .strength {
                                    Text(kind.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if exercise.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(.horizontal, AppTheme.memoCardPadding)
                        .frame(minHeight: AppTheme.touchTargetSecondary, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < list.count - 1 {
                        Divider()
                            .background(AppTheme.separator.opacity(0.5))
                    }
                }
            }
            .background(AppTheme.memoRecordSurface)

            HStack(spacing: 0) {
                Button {
                    HapticHelper.light()
                    if partKey == ExercisePickerViewModel.emptyBodyPartGroupKey {
                        createInitialBodyPart = nil
                    } else {
                        createInitialBodyPart = partKey
                    }
                    showCreateExercise = true
                } label: {
                    Text(String(localized: "picker_footer_add_exercise"))
                        .font(AppTheme.bodySecondaryFont.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                if hasMore {
                    Rectangle()
                        .fill(AppTheme.separator.opacity(0.5))
                        .frame(width: 0.5)
                        .frame(maxHeight: .infinity)
                    Button {
                        HapticHelper.light()
                        if isExpanded {
                            expandedBodyParts.remove(partKey)
                        } else {
                            expandedBodyParts.insert(partKey)
                        }
                    } label: {
                        Text(String(localized: isExpanded ? "picker_show_less" : "picker_show_all"))
                            .font(AppTheme.captionTypographyFont.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.memoCardPadding)
            .frame(height: AppTheme.touchTargetSecondary)
            .background(AppTheme.memoRecordSurface)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: AppTheme.cardCornerRadius,
                    bottomTrailingRadius: AppTheme.cardCornerRadius,
                    topTrailingRadius: 0
                )
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func relativeSubtitle(lastActivity: Date?) -> String {
        guard let d = lastActivity else {
            return String(localized: "picker_never_trained")
        }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale.current
        f.unitsStyle = .full
        return f.localizedString(for: d, relativeTo: Date())
    }

    @ViewBuilder
    private func legacyListContent(vm: ExercisePickerViewModel) -> some View {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameFiltered = keyword.isEmpty ? vm.exercises : vm.exercises.filter { ExerciseSearch.matches($0, keyword: keyword) }
        let filteredList = applyEquipmentFilter(nameFiltered)
            .sorted { e1, e2 in
                if e1.isFavorite != e2.isFavorite { return e1.isFavorite }
                return (e1.sortOrder, e1.name) < (e2.sortOrder, e2.name)
            }
        let equipTags = sortedEquipmentTags(from: vm.exercises)
        List {
            Section {
                Button {
                    HapticHelper.light()
                    createInitialBodyPart = nil
                    showCreateExercise = true
                } label: {
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.accent)
                        Text(String(localized: "picker_add_new_exercise"))
                            .font(AppTheme.bodySecondaryFont.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.spacingSM)
                    .contentShape(Rectangle())
                }
                .listRowInsets(EdgeInsets(top: AppTheme.spacingSM, leading: AppTheme.spacingLG, bottom: AppTheme.spacingSM, trailing: AppTheme.spacingLG))
            }
            if !equipTags.isEmpty {
                Section {
                    equipmentFilterChipsRow(tags: equipTags)
                        .listRowInsets(EdgeInsets(top: 4, leading: AppTheme.spacingLG, bottom: 4, trailing: AppTheme.spacingLG))
                        .listRowBackground(Color.clear)
                }
            }
            Section {
                ForEach(filteredList, id: \.id) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack(spacing: AppTheme.spacingMD) {
                            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                Text(exercise.name)
                                    .font(AppTheme.bodySecondaryFont.weight(.medium))
                                    .foregroundStyle(AppTheme.primaryText)
                                let kind = ExerciseKind(stored: exercise.exerciseKind)
                                if kind != .strength {
                                    Text(kind.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.accent)
                                }
                                if !exercise.bodyPartTag.isEmpty {
                                    Text(exercise.bodyPartTag)
                                        .font(AppTheme.captionTypographyFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            Spacer()
                            if exercise.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(.vertical, AppTheme.spacingXS)
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func sortedEquipmentTags(from exercises: [Exercise]) -> [String] {
        let tags = Set(exercises.map { $0.equipmentTag.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return tags.sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    private func applyEquipmentFilter(_ exercises: [Exercise]) -> [Exercise] {
        guard let t = equipmentFilterTag, !t.isEmpty else { return exercises }
        return exercises.filter { $0.equipmentTag == t }
    }

    @ViewBuilder
    private func equipmentFilterChipsRow(tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                equipmentFilterChip(title: String(localized: "picker_equipment_all"), isSelected: equipmentFilterTag == nil) {
                    equipmentFilterTag = nil
                }
                ForEach(tags, id: \.self) { tag in
                    equipmentFilterChip(title: tag, isSelected: equipmentFilterTag == tag) {
                        equipmentFilterTag = equipmentFilterTag == tag ? nil : tag
                    }
                }
            }
            .padding(.vertical, AppTheme.spacingXS)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "picker_equipment_filter_a11y"))
    }

    private func equipmentFilterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticHelper.light()
            action()
        } label: {
            Text(title)
                .font(AppTheme.captionTypographyFont.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent : AppTheme.memoInputCellFill)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppTheme.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func createViewModelOnce() {
        guard viewModel == nil else { return }
        let vm = ExercisePickerViewModel(
            exerciseRepository: ExerciseRepository(modelContext: modelContext),
            workoutRepository: WorkoutRepository(modelContext: modelContext)
        )
        viewModel = vm
        vm.load()
    }
}

#Preview {
    ExercisePickerView(onSelect: { _ in })
        .modelContainer(for: Exercise.self, inMemory: true)
}
