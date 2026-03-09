// File: Modules/Exercise/ExercisePickerView.swift

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var allExercises: [Exercise] = []

    private var filtered: [Exercise] {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        let base = keyword.isEmpty ? allExercises : allExercises.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
        return base.sorted { e1, e2 in
            if e1.isFavorite != e2.isFavorite { return e1.isFavorite }
            return (e1.sortOrder, e1.name) < (e2.sortOrder, e2.name)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered, id: \.id) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            if exercise.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                            Text(exercise.bodyPartTag)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "種目を検索")
            .navigationTitle("種目を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .onAppear { loadExercises() }
        }
    }

    private func loadExercises() {
        let repo = ExerciseRepository(modelContext: modelContext)
        allExercises = (try? repo.fetchAllExercises()) ?? []
    }
}

#Preview {
    ExercisePickerView(onSelect: { _ in })
        .modelContainer(for: Exercise.self, inMemory: true)
}
