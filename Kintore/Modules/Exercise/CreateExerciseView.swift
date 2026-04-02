// File: Modules/Exercise/CreateExerciseView.swift
// カスタム種目作成。初期部位を外から渡せる。保存は onSave で親に委譲。

import SwiftUI

/// 部位候補（WorkoutStartViewModel.orderedBodyParts と一致させる）
private let bodyPartOptions = ["胸", "背中", "脚", "肩", "腕", "体幹", "有酸素"]

struct CreateExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    let initialBodyPart: String?
    let onSave: (String, String, String, ExerciseKind) -> Void

    @State private var name = ""
    @State private var bodyPart: String
    @State private var equipment = ""
    @State private var exerciseKind: ExerciseKind = .strength

    init(initialBodyPart: String? = nil, onSave: @escaping (String, String, String, ExerciseKind) -> Void) {
        self.initialBodyPart = initialBodyPart
        self.onSave = onSave
        let part = initialBodyPart.flatMap { bodyPartOptions.contains($0) ? $0 : nil } ?? bodyPartOptions[0]
        _bodyPart = State(initialValue: part)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "create_exercise_name"), text: $name)
                        .textContentType(.name)
                        .font(AppTheme.bodyFont)
                } header: {
                    Text(String(localized: "create_exercise_name"))
                        .font(AppTheme.subheadlineFont.weight(.medium))
                }

                Section {
                    Picker(String(localized: "create_exercise_kind"), selection: $exerciseKind) {
                        ForEach(ExerciseKind.allCases) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(String(localized: "create_exercise_type_header"))
                        .font(AppTheme.subheadlineFont.weight(.medium))
                } footer: {
                    Text(String(localized: "create_exercise_type_footer"))
                        .font(AppTheme.captionTypographyFont)
                }

                Section {
                    Picker(String(localized: "create_exercise_body_part"), selection: $bodyPart) {
                        ForEach(bodyPartOptions, id: \.self) { part in
                            Text(part).tag(part)
                                .font(AppTheme.bodyFont)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(String(localized: "create_exercise_body_part"))
                        .font(AppTheme.subheadlineFont.weight(.medium))
                }

                Section {
                    TextField(String(localized: "create_exercise_equipment"), text: $equipment)
                        .textContentType(.none)
                        .font(AppTheme.bodyFont)
                } header: {
                    Text(String(localized: "create_exercise_equipment_header"))
                        .font(AppTheme.subheadlineFont.weight(.medium))
                }
            }
            .scrollContentBackground(.hidden)
            .tint(AppTheme.accent)
            .appTabRootChrome()
            .navigationTitle(String(localized: "create_exercise_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { dismiss() }
                        .font(AppTheme.bodyFont)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common_save")) {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, bodyPart, equipment.trimmingCharacters(in: .whitespacesAndNewlines), exerciseKind)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateExerciseView(initialBodyPart: "胸", onSave: { _, _, _, _ in })
}
