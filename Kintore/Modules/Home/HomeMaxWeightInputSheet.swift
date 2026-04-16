// File: Modules/Home/HomeMaxWeightInputSheet.swift
// ホームから種目ごとに MAX（重量）を入力するシート

import SwiftUI

struct HomeMaxWeightInputSheet: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.dismiss) private var dismiss

    let exerciseName: String
    @Binding var weightText: String
    var onSave: () -> Void

    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "simple_record_weight_placeholder"), text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(AppTheme.numericEmphasisFont)
                        .focused($fieldFocused)
                    Text(weightUnit)
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } footer: {
                    Text(String(localized: "home_max_weight_sheet_hint"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common_save")) {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                fieldFocused = true
            }
        }
    }
}
