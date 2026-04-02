// File: Modules/Exercise/ExerciseListView.swift
// 種目マスタ一覧（設定からの導線）。追加・削除。プリセットは削除不可。

import SwiftUI
import SwiftData

private enum ExerciseFormOptions {
    /// CreateExerciseView の部位候補と一致
    static let bodyParts = ["胸", "背中", "脚", "肩", "腕", "体幹", "有酸素"]
}

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exercises: [Exercise] = []
    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var exerciseToEdit: Exercise?
    @State private var bodyPartFilter: String?
    @State private var equipmentFilterTag: String?
    @State private var favoritesOnly = false

    private var filtered: [Exercise] {
        var list = exercises
        if favoritesOnly {
            list = list.filter(\.isFavorite)
        }
        if let bp = bodyPartFilter, !bp.isEmpty {
            list = list.filter { $0.bodyPartTag == bp }
        }
        if let eq = equipmentFilterTag, !eq.isEmpty {
            list = list.filter { $0.equipmentTag == eq }
        }
        let k = searchText.trimmingCharacters(in: .whitespaces)
        if k.isEmpty { return list }
        return list.filter { ExerciseSearch.matches($0, keyword: k) }
    }

    private var sortedBodyPartTags: [String] {
        let tags = Set(exercises.map { $0.bodyPartTag.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return tags.sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    private var sortedEquipmentTags: [String] {
        let tags = Set(exercises.map { $0.equipmentTag.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return tags.sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                filterSection
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            ForEach(filtered, id: \.id) { exercise in
                Button {
                    exerciseToEdit = exercise
                } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(exercise.name)
                                    .font(AppTheme.bodyTypographyFont)
                                    .foregroundStyle(.primary)
                                if exercise.isPreset {
                                    Text(String(localized: "exercise_preset_badge"))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(Capsule())
                                }
                            }
                            exerciseKindSubtitle(for: exercise)
                            HStack(spacing: 8) {
                                if !exercise.bodyPartTag.isEmpty {
                                    Text(exercise.bodyPartTag)
                                        .font(AppTheme.captionTypographyFont)
                                        .foregroundStyle(.secondary)
                                }
                                if !exercise.equipmentTag.isEmpty {
                                    Text(exercise.equipmentTag)
                                        .font(AppTheme.captionTypographyFont)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Spacer()
                        if exercise.isFavorite {
                            Image(systemName: "star.fill")
                                .font(AppTheme.captionTypographyFont)
                                .foregroundStyle(AppTheme.accent)
                        }
                        Image(systemName: "chevron.right")
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(String(localized: "common_edit")) {
                        exerciseToEdit = exercise
                    }
                }
            }
            .onDelete(perform: deleteExercises)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .tint(AppTheme.accent)
        .appTabRootChrome()
        .searchable(text: $searchText, prompt: String(localized: "exercise_search_prompt"))
        .navigationTitle(String(localized: "nav_exercise_list"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "common_add")) {
                    showAddSheet = true
                }
            }
        }
        .onAppear { loadExercises() }
        .sheet(isPresented: $showAddSheet) {
            CreateExerciseView(initialBodyPart: nil) { name, bodyPart, equipment, kind in
                insertExerciseFromCreate(name: name, bodyPart: bodyPart, equipment: equipment, kind: kind)
                showAddSheet = false
                loadExercises()
            }
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
        .sheet(item: $exerciseToEdit) { exercise in
            ExerciseEditView(exercise: exercise, onSave: {
                exerciseToEdit = nil
                loadExercises()
            }, onCancel: { exerciseToEdit = nil })
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
    }

    @ViewBuilder
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Toggle(String(localized: "exercise_list_favorites_only"), isOn: $favoritesOnly)
                .font(AppTheme.captionTypographyFont)
            if !sortedBodyPartTags.isEmpty {
                Text(String(localized: "create_exercise_body_part"))
                    .font(AppTheme.captionTypographyFont.weight(.semibold))
                    .foregroundStyle(.secondary)
                filterChipRow(
                    allTitle: String(localized: "picker_body_part_all"),
                    tags: sortedBodyPartTags,
                    selection: $bodyPartFilter
                )
            }
            if !sortedEquipmentTags.isEmpty {
                Text(String(localized: "create_exercise_equipment_header"))
                    .font(AppTheme.captionTypographyFont.weight(.semibold))
                    .foregroundStyle(.secondary)
                filterChipRow(
                    allTitle: String(localized: "picker_equipment_all"),
                    tags: sortedEquipmentTags,
                    selection: $equipmentFilterTag
                )
            }
        }
    }

    private func filterChipRow(allTitle: String, tags: [String], selection: Binding<String?>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                filterChip(title: allTitle, isSelected: selection.wrappedValue == nil) {
                    selection.wrappedValue = nil
                }
                ForEach(tags, id: \.self) { tag in
                    filterChip(title: tag, isSelected: selection.wrappedValue == tag) {
                        selection.wrappedValue = selection.wrappedValue == tag ? nil : tag
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticHelper.light()
            action()
        } label: {
            Text(title)
                .font(AppTheme.captionTypographyFont.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent : Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func insertExerciseFromCreate(name: String, bodyPart: String, equipment: String, kind: ExerciseKind) {
        let repo = ExerciseRepository(modelContext: modelContext)
        let count = (try? repo.fetchAllExercises().count) ?? 0
        var cardio: String?
        if kind == .cardio {
            cardio = CardioInputStyle.treadmill.rawValue
        }
        let ex = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            bodyPartTag: bodyPart,
            equipmentTag: equipment.trimmingCharacters(in: .whitespacesAndNewlines),
            defaultRestSeconds: 90,
            exerciseKind: kind.rawValue,
            cardioInputStyle: cardio,
            isPreset: false,
            isFavorite: false,
            sortOrder: count,
            createdAt: Date()
        )
        try? repo.insertExercise(ex)
    }

    @ViewBuilder
    private func exerciseKindSubtitle(for exercise: Exercise) -> some View {
        let kind = ExerciseKind(stored: exercise.exerciseKind)
        if kind != .strength {
            Text(kind.displayName)
                .font(.caption2)
                .foregroundStyle(AppTheme.accent)
        }
    }

    private func loadExercises() {
        let repo = ExerciseRepository(modelContext: modelContext)
        exercises = (try? repo.fetchAllExercises()) ?? []
    }

    private func deleteExercises(at offsets: IndexSet) {
        let repo = ExerciseRepository(modelContext: modelContext)
        for index in offsets {
            guard index < filtered.count else { continue }
            let exercise = filtered[index]
            if exercise.isPreset { continue }
            try? repo.deleteExercise(exercise)
        }
        loadExercises()
    }
}

extension Exercise: Identifiable {}

// MARK: - 種目編集シート
private struct ExerciseEditView: View {
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var searchKeywords: String = ""
    @State private var exerciseKind: ExerciseKind = .strength
    @State private var bodyPart: String = "胸"
    @State private var equipment: String = ""
    @State private var defaultRestSeconds: Int = 90
    /// 0 = 未設定（記録時は 60 秒フォールバック）
    @State private var warmupRestPick: Int = 0
    @State private var isFavorite: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "create_exercise_name"), text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section {
                    TextField(String(localized: "exercise_search_keywords_placeholder"), text: $searchKeywords, axis: .vertical)
                        .font(AppTheme.bodyFont)
                } header: {
                    Text(String(localized: "exercise_search_keywords_header"))
                } footer: {
                    Text(String(localized: "exercise_search_keywords_footer"))
                        .font(AppTheme.captionTypographyFont)
                }
                Section {
                    Picker(String(localized: "create_exercise_kind"), selection: $exerciseKind) {
                        ForEach(ExerciseKind.allCases) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                    .pickerStyle(.menu)
                } footer: {
                    if exerciseKind == .cardio {
                        Text(String(localized: "exercise_cardio_treadmill_footer"))
                            .font(AppTheme.captionTypographyFont)
                    }
                }
                Section(String(localized: "exercise_edit_body_equipment")) {
                    TextField(String(localized: "create_exercise_body_part"), text: $bodyPart)
                    TextField(String(localized: "create_exercise_equipment"), text: $equipment)
                }
                Section {
                    Picker(String(localized: "settings_rest_default"), selection: $defaultRestSeconds) {
                        Text(String(localized: "settings_rest_60s")).tag(60)
                        Text(String(localized: "settings_rest_90s")).tag(90)
                        Text(String(localized: "settings_rest_120s")).tag(120)
                        Text(String(localized: "settings_rest_180s")).tag(180)
                    }
                }
                Section {
                    Picker(String(localized: "exercise_edit_warmup_rest"), selection: $warmupRestPick) {
                        Text(String(localized: "exercise_edit_warmup_rest_auto")).tag(0)
                        Text(String(localized: "settings_rest_60s")).tag(60)
                        Text(String(localized: "settings_rest_90s")).tag(90)
                        Text(String(localized: "settings_rest_120s")).tag(120)
                        Text(String(localized: "settings_rest_180s")).tag(180)
                    }
                } footer: {
                    Text(String(localized: "exercise_edit_warmup_rest_footer"))
                        .font(AppTheme.captionTypographyFont)
                }
                Section {
                    Toggle(String(localized: "exercise_edit_favorite"), isOn: $isFavorite)
                }
            }
            .scrollContentBackground(.hidden)
            .tint(AppTheme.accent)
            .appTabRootChrome()
            .navigationTitle(String(localized: "nav_exercise_edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "workout_save")) {
                        save()
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = exercise.name
                searchKeywords = exercise.searchKeywords
                exerciseKind = ExerciseKind(stored: exercise.exerciseKind)
                bodyPart = exercise.bodyPartTag.isEmpty ? "胸" : exercise.bodyPartTag
                equipment = exercise.equipmentTag
                defaultRestSeconds = exercise.defaultRestSeconds ?? 90
                warmupRestPick = exercise.defaultRestSecondsWarmUp ?? 0
                isFavorite = exercise.isFavorite
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        exercise.name = trimmed
        exercise.searchKeywords = searchKeywords.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.exerciseKind = exerciseKind.rawValue
        if exerciseKind == .cardio {
            exercise.cardioInputStyle = CardioInputStyle.treadmill.rawValue
        } else {
            exercise.cardioInputStyle = nil
        }
        exercise.bodyPartTag = bodyPart
        exercise.equipmentTag = equipment.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.defaultRestSeconds = defaultRestSeconds
        exercise.defaultRestSecondsWarmUp = warmupRestPick == 0 ? nil : warmupRestPick
        exercise.isFavorite = isFavorite
        try? ExerciseRepository(modelContext: modelContext).updateExercise(exercise)
    }
}

#Preview {
    NavigationStack {
        ExerciseListView()
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}
