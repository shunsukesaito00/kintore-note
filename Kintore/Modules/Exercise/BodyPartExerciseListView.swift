// File: Modules/Exercise/BodyPartExerciseListView.swift
// 指定部位の種目だけを全件表示。WorkoutStartView の「すべて表示」から sheet で表示。

import SwiftUI

struct BodyPartExerciseListView: View {
    @Environment(\.dismiss) private var dismiss
    let bodyPart: String
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    EmptyStateView(
                        message: String(localized: "body_part_exercise_empty"),
                        icon: "dumbbell"
                    )
                } else {
                    List {
                        ForEach(exercises, id: \.id) { exercise in
                            Button {
                                HapticHelper.light()
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                HStack(spacing: AppTheme.spacingMD) {
                                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                        Text(exercise.name)
                                            .font(AppTheme.bodyTypographyFont.weight(.medium))
                                            .foregroundStyle(AppTheme.primaryText)
                                        if !exercise.equipmentTag.isEmpty {
                                            Text(exercise.equipmentTag)
                                                .font(AppTheme.captionTypographyFont)
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(AppTheme.captionTypographyFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                .padding(.vertical, AppTheme.spacingXS)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(AppTheme.appBackground)
            .navigationTitle(bodyPart)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.memoNavBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_close")) { dismiss() }
                        .font(AppTheme.bodyTypographyFont)
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                }
            }
        }
    }
}

#Preview {
    BodyPartExerciseListView(bodyPart: "胸", exercises: [], onSelect: { _ in })
}
